=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

 Please email comments or questions to the public Ensembl
 developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

 Questions may also be sent to the Ensembl help desk at
 <http://www.ensembl.org/Help/Contact>.

=cut

package Bio::EnsEMBL::Variation::Pipeline::DumpVEP::DumpVEP_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

sub default_options {
  my ($self) = @_;

  # The hash returned from this function is used to configure the
  # pipeline, you can supply any of these options on the command
  # line to override these default values.
    
  # You shouldn't need to edit anything in this file other than
  # these values, if you find you do need to then we should probably
  # make it an option here, contact the variation team to discuss
  # this - patches are welcome!

  return {

    # general pipeline options that you should change to suit your environment
       
    hive_force_init => 1,
    hive_use_param_stack => 0,
    hive_use_triggers => 0,
    hive_auto_rebalance_semaphores => 0, 
    hive_no_init => 0,
    # the location of your checkout of the ensembl API (the hive looks for SQL files here)
        
    ensembl_cvs_root_dir    => $ENV{'HOME'} . '/Git',
    hive_root_dir           => $ENV{'HOME'} . '/Git/ensembl-hive', 
    # a name for your pipeline (will also be used in the name of the hive database)
        
    pipeline_name           => 'dump_vep',

    # a directory to keep hive output files and your registry file, you should
    # create this if it doesn't exist

    pipeline_dir            => '/lustre/scratch109/ensembl/'.$ENV{'USER'}.'/'.$self->o('pipeline_name'),

    # a directory where hive workers will dump STDOUT and STDERR for their jobs
    # if you use lots of workers this directory can get quite big, so it's
    # a good idea to keep it on lustre, or some other place where you have a 
    # healthy quota!
        
    output_dir              => $self->o('pipeline_dir').'/hive_output',
    
    # command line stuff for VEP
    # gets prefixed with ensembl_cvs_root_dir/ensembl-tools/scripts/variant_effect_predictor/
    vep_command  => 'variant_effect_predictor.pl --build all',
    
    # you might want to add a -I here to point to a master repo instead of your default branch picked up by PERL5LIB
    perl_command => $^X,
        
    # specify which servers to scan for databases to dump
    dump_servers            => [
      {
        host => 'ens-staging1',
        port => 3306,
        user => 'ensro',
        pass => $self->o('dump_db_password'),
      },
      {
        host => 'ens-staging2',
        port => 3306,
        user => 'ensro',
        pass => $self->o('dump_db_password'),
      },
    ],
    
    # dump databases of this version number
    ensembl_release => undef,
    
    # add refseq, merged dumps?
    refseq => 1,
    merged => 1,
    
    # include or exclude DBs with these patterns
    include_pattern => undef,
    exclude_pattern => undef,
    
    # special flags apply to certain species
    species_flags => {
      homo_sapiens => {
        sift => 'b',
        polyphen => 'b',
        regulatory => 1,
        freq_file => '/nfs/ensembl/wm2/VEP/cache/ALL_1KG_ESP_freqs_with_alleles.txt,AFR,AMR,ASN,EUR,AA,EA',
      },
      mus_musculus => {
        regulatory => 1,
        sift => 'b',
      },
      bos_taurus => {
        sift => 'b',
      },
      canis_familiaris => {
        sift => 'b',
      },
      danio_rerio => {
        sift => 'b',
      },
      equus_caballus => {
        sift => 'b',
      },
      gallus_gallus => {
        sift => 'b',
      },
      rattus_norvegicus => {
        sift => 'b',
      },
      sus_scrofa => {
        sift => 'b',
      },
    },

    # configuration for the various resource options used in the pipeline
    # EBI farm users should either change these here, or override them on the
    # command line to suit the EBI farm. The names of each option hopefully
    # reflect their usage, but you may want to change the details (memory
    # requirements, queue parameters etc.) to suit your own data
        
    default_lsf_options => '-R"select[mem>2000] rusage[mem=2000]" -M2000',
    urgent_lsf_options  => '-q yesterday -R"select[mem>2000] rusage[mem=2000]" -M2000',
    highmem_lsf_options => '-R"select[mem>15000] rusage[mem=15000]" -M15000', # this is Sanger LSF speak for "give me 15GB of memory"
    long_lsf_options    => '-q long -R"select[mem>2000] rusage[mem=2000]" -M2000',

    # init_pipeline.pl will create the hive database on this machine, naming it
    # <username>_<pipeline_name>, and will drop any existing database with this
    # name

    hive_db_host    => 'ens-variation',
    hive_db_port    => 3306,
    hive_db_user    => 'ensadmin',

    pipeline_db => {
      -host   => $self->o('hive_db_host'),
      -port   => $self->o('hive_db_port'),
      -user   => $self->o('hive_db_user'),
      -pass   => $self->o('hive_db_password'),            
      -dbname => $ENV{'USER'}.'_'.$self->o('pipeline_name'),
      -driver => 'mysql',
    },
  };
}


sub resource_classes {
  my ($self) = @_;
  return {
    'default' => { 'LSF' => $self->o('default_lsf_options') },
    'urgent'  => { 'LSF' => $self->o('urgent_lsf_options')  },
    'highmem' => { 'LSF' => $self->o('highmem_lsf_options') },
    'long'    => { 'LSF' => $self->o('long_lsf_options')    },
  };
}

sub pipeline_analyses {
  my ($self) = @_;

  my @common_params = map {$_ => $self->o($_) || undef} qw(
    ensembl_release
    ensembl_cvs_root_dir
    pipeline_dir
    perl_command
    refseq
    merged
  );
   
  my @analyses = (
    {
      -logic_name    => 'init_dump_vep',
      -module        => 'Bio::EnsEMBL::Variation::Pipeline::DumpVEP::InitDump',
      -parameters    => {
        include_pattern => $self->o('include_pattern'),
        exclude_pattern => $self->o('exclude_pattern'),
        dump_servers    => $self->o('dump_servers'),
        @common_params
      },
      -input_ids     => [{}],
      -rc_name       => 'default',
      -meadow_type   => 'LOCAL',
      -hive_capacity => 1,
      -flow_into     => {
        '2' => ['dump_vep', 'finish_dump'],
        '3' => ['merge_vep']
      },
    },
    {
      -logic_name    => 'dump_vep',
      -module        => 'Bio::EnsEMBL::Variation::Pipeline::DumpVEP::DumpVEP',
      -parameters    => {
        species_flags        => $self->o('species_flags'),
        vep_command          => $self->o('vep_command'),
        @common_params
      },
      -rc_name       => 'highmem',
      -hive_capacity => 3,
    },
    {
      -logic_name => 'merge_vep',
      -module     => 'Bio::EnsEMBL::Variation::Pipeline::DumpVEP::MergeVEP',
      -parameters => {
        @common_params
      },
      -wait_for   => ['dump_vep'],
    },
    {
      -logic_name => 'finish_dump',
      -module     => 'Bio::EnsEMBL::Variation::Pipeline::DumpVEP::FinishDump',
      -parameters => {
        @common_params
      },
      -wait_for   => ['merge_vep'],
    }
  );

  return \@analyses;
}

1;

