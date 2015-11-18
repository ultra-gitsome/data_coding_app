#!/usr/bin/perl -s
use strict;
use warnings;
use YAML::XS qw(LoadFile DumpFile Load Dump);
#use YAML::Syck;
use Excel::Writer::XLSX;
#use Spreadsheet::WriteExcel;
use DBI;
use Modern::Perl;
use re qw/eval/; # Considered experimental.

use Socket;
use POE qw(Wheel::SocketFactory
  Wheel::ReadWrite
  Driver::SysRW
  Filter::Reference
);

our $server_version = 0.001008;
our $publish_date = '2015.1.21';

my $project_name = 'dissertation';
my $dir = "c:/Users/WinUser/Documents/Timeline/sebastian/capella/aquad7/";
my $yml_dir = "yml/";
my $cod_dir = "cod/";
my $recod_dir = "re_cod/";
my $txt_dir = "txt/";
my $atx_txt_dir = "atx_txt/";
my $recover_dir = "recovery/";
my $src_files_filename = 'aqd7{mem.fil'; ## very strange name...
my $atx_files_filename = '{S_Analysis}'; ## very strange name...

my $trace = 1;
my $runtime = 1;
my $set_frozen = 0;
my $overwrite_post_parse = 0;
my $test_extra_chars = 10;

my $file = 'KirkTichnor_2014.4.11.txt';
my $words_file = 'special_words.yml';
#my $files_file = 'text_files_to_parse.yml';
my $files_file = 'dissertation_parse_files.yml';
my $yamlfile = "interviews.yml";
my $runstatusfile = "run_status.yml";
my $codingfile = "data_coding.yml";
my $codingfilenam = "data_coding";
my $testcodingfile = "test_data_coding.yml";
my $bakcodingfile = "bak_data_coding.yml";
my $parsingfile = "data_parsing.yml";
my $parsingfilenam = "data_parsing";
my $testparsingfile = "test_data_parsing.yml";
my $postparsefile = "post_parse_data.yml";
my $postparsefilenam = "post_parse_data";
my $postcodingfile = "post_coding_data.yml";
my $postcodingfilenam = "post_coding_data";
my $analyticsfile = "coding_analysis.yml";
my $testanalyticsfile = "test_coding_analysis.yml";
my $v2nalyticsfile = "coding_analysis_v2.yml";
my $statsfile = "coding_stats.yml";
my $statsfilenam = "coding_stats";
my $stats2xfile = "coding_stats_2x.yml";
my $stats2xfilenam = "coding_stats_2x";
my $statslinkfile = "coding_stats_linkage.yml";
my $statslinkfilenam = "coding_stats_linkage";
my $statsupdnfile = "coding_stats_updn.yml";
my $statsupdnfilenam = "coding_stats_updn";
my $statsaspectsfile = "coding_stats_aspects.yml";
my $statsaspectsfilenam = "coding_stats_aspects";
my $stats_basefile = "coding_base_stats.yml";

my $clusterfile = "clustering_stats.yml";
my $clusterfilenam = "clustering_stats";
my $tatssheetsfile = "EE_coding_stats";
my @file_list = ('KirkTichnor_2014.4.11.txt');
my @outfile_list = ();
my %file_list_href = ();

my $Mdata = undef;
my $run_config = undef;
my $special_words = undef;
my $pre_text_config = undef;
my $post_text_config = undef;
my $files_loaded = undef;
my $lines_final = undef;
my $topic_to_code_mapping = undef;
my $code_replacement_mapping = undef;

my $run_status = undef;
my $data_analysis = undef;
my $anal_coding = undef;
my $data_stats = undef;
my $data_stats_2x = undef;
my $data_stats_linkage = undef;
my $data_stats_updn = undef;
my $data_coding = undef;
my $data_parsing = undef;
my $new_data_parsing = undef;
my $data_postparse = undef;
my $new_data_postparse = undef;
my $data_clustering = undef;
my $data_stats_aspects = undef;
my $stats_base_disp = undef;
my $data_post_coding = undef;
my $new_data_post_coding = undef;

## giant counter hash for codes
my $codectrhref = {};
my $final_codectrhref = {};
my $nested_codectrhref = {};
my $prime_codectrhref = {};
my $aspectctrhref = {};
my $temp_code_map_href = {};

my $codes_dirty = {};
my $work_type = {'1' => 'parse files','3' => 'split tblocks into parts','5' => 'write atx files','7' => 'recode stats','10' => 're-code aco files','12' => 'calc code dispersion','14' => 'write xlsx files'};
my $skip_first_line_in_parsed_data = 1;
my $write_these_files = {do_these => {"K0T0" => 1,"M0F0" => 1}};
my $max_line_length = 500;
my $dtg = undef;
my %col_converter = ('1'=>'B','2'=>'C','3'=>'D','4'=>'E','5'=>'F','6'=>'G','7'=>'H','8'=>'I','9'=>'J','10'=>'K','11'=>'L','12'=>'M','13'=>'N','14'=>'O','15'=>'P','16'=>'Q','17'=>'R','18'=>'S','19'=>'T','20'=>'U','21'=>'V','22'=>'W','23'=>'X','24'=>'Y','25'=>'Z','26'=>'AA','27'=>'AB','28'=>'AC','29'=>'AD','30'=>'AE','31'=>'AF','32'=>'AG','33'=>'AH','34'=>'AI','35'=>'AJ','36'=>'AK','37'=>'AL','38'=>'AM','39'=>'AN','40'=>'AO','41'=>'AP','42'=>'AQ','43'=>'AR','44'=>'AS','45'=>'AT','46'=>'AU','47'=>'AV','48'=>'AW','49'=>'AX','50'=>'AY','51'=>'AZ','52'=>'BA','53'=>'BB','54'=>'BC','55'=>'BD','56'=>'BE','57'=>'BF','58'=>'BG','59'=>'BH','60'=>'BI','61'=>'BJ','62'=>'BK','63'=>'BL','64'=>'BM','65'=>'BN','66'=>'BO','67'=>'BP','68'=>'BQ','69'=>'BR','70'=>'BS','71'=>'BT','72'=>'BU','73'=>'BV','74'=>'BW','75'=>'BX','76'=>'BY','77'=>'BZ','78'=>'CA','79'=>'CB','80'=>'CC','81'=>'CD','82'=>'CE','83'=>'CF','84'=>'CG','85'=>'CH','86'=>'CI','87'=>'CJ','88'=>'CK','89'=>'CL','90'=>'CM','91'=>'CN','92'=>'CO','93'=>'CP','94'=>'CQ','95'=>'CR','96'=>'CS','97'=>'CT','98'=>'CU','99'=>'CV','100'=>'CW',);

#	print "Time... local[" . localtime();
my ($d,$m,$y,$h,$min) = (localtime)[3,4,5,2,1];
$dtg = $y+1900;
$m++;
$dtg = $dtg . "_" . $m . "_" . $d . "_" . $h . "_" . $min;
print "Time: [".$y.":".$m.":".$d.":".$h."] dtg [$dtg]\n";

say "Welcome to AQUAD CADO Parser -- finder of phrase codes and AQUAD atx formater" if $runtime;




######
## Global node variables
######
my $node = 1;
my $me = undef;
my $mySN = undef;
my $whoami = "data_coder_server";
my $my_server_type = 'coder';
my $my_server_address = 'localhost';
my $my_server_port = 44500;    # Data coder port
my $init_server_message = "Data Coder Server";
my $my_shortform_server_type = 'Coder';

my $base_dir = "c:/Timing/";
my $conf_dir = "server_conf/";
my $conf2_dir = "config/system/";
my $log_dir = "server_log/";
#my $var_yaml_store_dir = "server_reg/";
my $server_conf_dir = $base_dir . $conf_dir;
my $server_conf2_dir = $base_dir . $conf2_dir;
#my $server_yaml_var_store_dir = $base_dir . $var_yaml_store_dir;
my $config_file_hub = "hubDescriptor.yml";
my $config_file = "nodeDescriptor.yml";

my $logfilename = 'server_log_node';
$logfilename = $log_dir . $logfilename . "_dc_01.txt";
open(my $lfh, '>>', $logfilename) or print "\nCould not open file '$logfilename' $!\n";

say $lfh "NEW Startup";
say $lfh "Start " . $init_server_message . " at [".localtime()."]. Version[".$server_version." ".$publish_date."]";

#$_pmgr->logout_tstamp_yml('logtype',0,'ymlstr',$logstr);

my $skip_db_config = 1;
my $socket_carp = 0;
my $topo_carp = 1;
my $testing = 0;
my $run_codes_trace = 1;

####
## declare globals to run timer for server kill
####
my $k_count = 0;
my $kill_session = 0;
my $kill_ct_delay = 3;

my $events = {};
my $event_code = undef;

#if($main::node_number) {
#	$node = $main::node_number;
#	print "Node number from start-up argument is [$node]\n";
#}
#my $clear_server_registrations = 0;
#if($main::clear_server_registrations) {
#	$clear_server_registrations = $main::clear_server_registrations;
#	print "Clear previous server registrations [$clear_server_registrations]\n";
#}
my $core_ip_address = undef;
my $my_ip_address = undef;


my $_files_file = $dir . $yml_dir . $files_file;

if(open(my $fh2, '<', $_files_file)) {
	$files_loaded = LoadFile($_files_file);
} else {
	die "\nERROR! cannot open [$files_file] [$!]";
}

## NOTE. THE ATX OUTFILES NEEDS SORTING OUT

if(defined $files_loaded) {
	if(exists $files_loaded->{files}) {
		say "Loading [".scalar(keys %{$files_loaded->{files}})."] text files for parsing" if $runtime;
		@file_list = ();
		foreach my $index (sort { $a <=> $b } keys %{$files_loaded->{files}}) {
			say "\tFile available, index[$index] [".$files_loaded->{files}->{$index}."]" if $runtime;
			if(exists $files_loaded->{active_parse}->{$index} and $files_loaded->{active_parse}->{$index}) {
				say "\t\tPushing onto active stack [$index] [".$files_loaded->{files}->{$index}."]" if $runtime;
				push @file_list,$files_loaded->{files}->{$index};
				$file_list_href{$index} = $files_loaded->{files}->{$index};
			}
			my $f = '';
			if($files_loaded->{atx_out}->{$index}) {
				$f = $files_loaded->{atx_out}->{$index};
			}
			push @outfile_list,$f;
		}
	}
}

#my $_words_file = $dir . $words_file;
my $_words_file = $dir . $yml_dir . $words_file;

if(open(my $fh2, '<', $_words_file)) {
	$run_config = LoadFile($_words_file);
} else {
	die "ERROR! cannot open [$words_file]\n";
}

$special_words = $run_config->{word_handling};
$pre_text_config = $run_config->{pre_text};
$post_text_config = $run_config->{post_text};
$topic_to_code_mapping = $run_config->{parse_coding}->{topic_to_code_map};
$code_replacement_mapping = $run_config->{parse_coding}->{code_replacment_map};


if(defined $run_config and scalar(keys %$run_config)) {
	say "Config Info; [".scalar(keys %{$files_loaded->{files}})."] categories of config for parsing" if $runtime;
	foreach my $key (keys %{$run_config}) {
		say "\tConfig cat [$key] options[".scalar(keys %{$run_config->{$key}})."] [".$run_config->{$key}."]" if $runtime;
		foreach my $subkey (keys %{$run_config->{$key}}) {
			say "\t\tOption [$subkey] value[".$run_config->{$key}->{$subkey}."]" if $runtime;
		}
	}
}

my $rsfile = $dir . $yml_dir . $runstatusfile;
if(open(my $fh3, '<', $rsfile)) {
	$run_status = LoadFile($rsfile);
} else {
#	die "\nERROR! cannot open [$rsfile] [$!]";
}
if(defined $run_status and scalar(keys %$run_status)) {
	say "Run Status Info is open; with keys[".scalar(keys %{$run_status})."]" if $runtime;
}


my $cfile = $dir . $yml_dir . $codingfile;
if(open(my $fh3, '<', $cfile)) {
	$data_coding = LoadFile($cfile);
} else {
	die "\nERROR! cannot open [$cfile] [$!]";
}

if(defined $data_coding and scalar(keys %$data_coding)) {
	say "Data Coding File Info; [".scalar(keys %{$data_coding})."] interviewee keys" if $runtime;
	foreach my $key (keys %{$data_coding}) {
		say "\tName key [$key] options[".scalar(keys %{$data_coding->{$key}})."] [".$data_coding->{$key}."]" if $runtime;
	}
}

#my $pfile = $dir . $yml_dir . $testparsingfile;
my $pfile = $dir . $yml_dir . $parsingfile;
if(open(my $fh3, '<', $pfile)) {
	$data_parsing = LoadFile($pfile);
} else {
	die "\nERROR! cannot open [$pfile] [$!]";
}
if(defined $data_parsing and scalar(keys %$data_parsing)) {
	say "Data Parsing File Info; [".scalar(keys %{$data_parsing})."] Topkeys" if $runtime;
	foreach my $key (keys %{$data_parsing}) {
		say "\tName topkey [$key] options[".scalar(keys %{$data_parsing->{$key}})."] [".$data_parsing->{$key}."]" if $runtime;
	}
}

my $ppfile = $dir . $yml_dir . $postparsefile;
if(open(my $fh3, '<', $ppfile)) {
	$data_postparse = LoadFile($ppfile);
} else {
#	die "\nERROR! cannot open [$ppfile] [$!]";
}
if(defined $data_postparse and scalar(keys %$data_postparse)) {
	say "Data Post Parsing File Info; [".scalar(keys %{$data_postparse})."] Topkeys" if $runtime;
	foreach my $key (keys %{$data_postparse}) {
		say "\tName topkey [$key] options[".scalar(keys %{$data_postparse->{$key}})."] [".$data_postparse->{$key}."]" if $runtime;
	}
}

my $pcfile = $dir . $yml_dir . $postcodingfile;
if(open(my $fh3, '<', $pcfile)) {
	$data_post_coding = LoadFile($pcfile);
} else {
#	die "\nERROR! cannot open [$ppfile] [$!]";
}
if(defined $data_post_coding and scalar(keys %$data_post_coding)) {
	say "Data Post Coding File Info; [".scalar(keys %{$data_post_coding})."] Topkeys" if $runtime;
	foreach my $key (keys %{$data_post_coding}) {
		say "\tName topkey [$key] options[".scalar(keys %{$data_post_coding->{$key}})."] [".$data_post_coding->{$key}."]" if $runtime;
	}
} else {
	## blank....
}

my $node_config_file = $server_conf_dir . $config_file;
my $hub_config_file = $server_conf2_dir . $config_file_hub;
my $configdata = {};
my $server_topology = {};
my $host_topology = {};
if(open(my $fh, '<', $hub_config_file)) {
	$configdata = LoadFile $hub_config_file;
}
if(exists $configdata->{node_config}) {
#	if(exists $configdata->{node_config}->{node_number}) {
#		$node = $configdata->{node_config}->{node_number};
#	}
#	$me = $configdata->{node_config}->{node_name};
#	$mySN = $configdata->{node_config}->{node_identifier};
#	$events = $configdata->{start_up}->{event_ids};
#	$server_topology = $configdata->{topology};
#	$host_topology = $configdata->{named_host_mapping};
}

my $dbh = undef;
if(!$skip_db_config) {
	####
	## get a DBI Mysql conn handle
	## this step interlaced with the loading of the yaml config file,
	## so if the node descriptor file fails to load, the dhb and the node fails
	#### 
	my $user = $configdata->{db_connection_conf}->{user};
	my $password = $configdata->{db_connection_conf}->{password};
	my $user2 = $configdata->{db_connection_conf}->{user2};
	my $password2 = $configdata->{db_connection_conf}->{password2};
	my $dbname = $configdata->{db_connection_conf}->{database};
	my $host_n_port = $configdata->{db_connection_conf}->{dsn};
	#my $dbh = undef;
	my $dbi = 'DBI:mysql:' . $dbname . ':' . $host_n_port;
	eval {
		$dbh = DBI->connect($dbi, $user, $password,
					{ RaiseError => 1 }
				);
	};
	if($@) {
		print "Error! In dbh conn with user[$user]\n\t $@\n";
		print "Trying with with user[$user2]\n";
		eval {
			$dbh = DBI->connect($dbi, $user2, $password2,
						{ RaiseError => 1 }
					);
		};
		if($@) {
			print "Epic S@#t fail! In dbh setup user[$user2]\n\t $@\n";
		}
	}

}

#####
# MAIN
#####

local $| = 1;
my $debug      = 1;        # be very very noisy
#our $station_reg = {};

######
# Set DB Configuration
######
my $pid = 0;
if(!$skip_db_config) {
	my $sql = "SELECT * FROM node_configuration WHERE node_identifier = '".$mySN."'";

	my $sth = $dbh->prepare($sql) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute();

	while (my $row_href = $sth->fetchrow_hashref()) {
		$pid = $row_href->{'id'};
		if($row_href->{'node_number'}) {
			$node = $row_href->{'node_number'};
			$events->{1} = $row_href->{'event_id_1'};
		}
		## ok - not very elegant...but very simple. 5 events is the limit for each node.
		if(exists $row_href->{'event_id_2'} && $row_href->{'event_id_2'}) {
			$events->{2} = $row_href->{'event_id_2'};
		}
		if(exists $row_href->{'event_id_3'} && $row_href->{'event_id_3'}) {
			$events->{3} = $row_href->{'event_id_3'};
		}
		if(exists $row_href->{'event_id_4'} && $row_href->{'event_id_4'}) {
			$events->{4} = $row_href->{'event_id_4'};
		}
		if(exists $row_href->{'event_id_5'} && $row_href->{'event_id_5'}) {
			$events->{5} = $row_href->{'event_id_5'};
		}
	}
}

fork and exit unless $debug;

######
## Tell the World who we are...
######
if($server_version) {
	my $pstring = "$init_server_message on [".$my_server_address.":".$my_server_port."]. Version[".$server_version." ".$publish_date."]";
	print $pstring . "\n";
	say $lfh $pstring;
}

my $init_poe = 0;
POE::Session->create(
  inline_states => {
    _start => \&parent_start,
    _stop  => \&parent_stop,

    socket_birth => \&socket_birth,
    socket_death => \&socket_death,
    full_stop => \&full_stop,
  }
);

# $poe_kernel is exported from POE
$poe_kernel->run();

close $lfh;

exit;


####################################

sub parent_start {
  my $heap = $_[HEAP];

  print "= L = Listener started [".localtime."]\n" if $socket_carp;
  say $lfh "= L = Listener started [".localtime."] on[$my_server_address][$my_server_port]";

  $heap->{listener} = POE::Wheel::SocketFactory->new(
    BindAddress  => $my_server_address,
    BindPort     => $my_server_port,
    Reuse        => 'yes',
    SuccessEvent => 'socket_birth',
    FailureEvent => 'socket_death',
  );
}
sub parent_stop {
	my $heap = $_[HEAP];
	if ($heap->{listener}) {
		delete $heap->{listener};
		print "= L = Listener is dead - (ParentStop Kill)\n" if $socket_carp;
	}
	if ($heap->{session}) {
		delete $heap->{session};
		print "= L = Session death - (ParentStop Kill)\n" if $socket_carp;
	}
}
sub full_stop {
	my $heap = $_[HEAP];
	print "...making shutdown.\n";
	if ($heap->{listener}) {
		delete $heap->{listener};
		print "= L = Listener is dead\n" if $socket_carp;
	}
	if ($heap->{session}) {
		delete $heap->{session};
		print "= L = Session is dead\n" if $socket_carp;
	}
	die "Node service is shutting down. G'bye!\n";
}

##########
# SOCKET #
##########

sub socket_birth {
  my ($socket, $address, $port) = @_[ARG0, ARG1, ARG2];
  $address = inet_ntoa($address);
  $init_poe = 1;

  print "= S = Socket birth: init_state[$init_poe]\n" if $socket_carp;

	POE::Session->create(
		inline_states => {
			_start => \&socket_success,
			_stop  => \&socket_death,

			socket_rcvd_input => \&socket_rcvd_input,
			socket_death => \&socket_death,
			kill_switch => \&kill_switch,
			wait_kill => \&wait_kill,
		},
		args => [$socket, $address, $port],
	);

}
sub socket_death {
	my $heap = $_[HEAP];
	print "= D = Socket is dying...\n" if $socket_carp;
	if(!$init_poe) { 
		print "\nCRITICAL FAIL! Server will not start. Verify IP address [$my_server_address] and port[$my_server_port].\n\n"; 
		say $lfh "\tCRITICAL FAIL! Server will not start. Verify IP address[$my_server_address] and port[$my_server_port]."; 
	} 
	say $lfh "= D = Socket is dying...";
	
	if ($heap->{socket_wheel}) {
		print "= S = Socket is dead\n" if $socket_carp;
		delete $heap->{socket_wheel};
	}
	if ($_[HEAP]->{shutdown_now}) {
		if($heap->{socket_is_not_dead}) {
			print "Call made for Full Stop [".$heap->{socket_is_not_dead}."]\n";
			$heap->{socket_is_not_dead} = 0;
			full_stop($heap);
		}
	}
}
sub socket_success {
	my ($heap, $kernel, $connected_socket, $address, $port) =
		@_[HEAP, KERNEL, ARG0, ARG1, ARG2];

	print "= I = CONNECTION from $address : $port \n" if $debug;

	my $yaml = 'YAML';
	$heap->{socket_wheel} = POE::Wheel::ReadWrite->new(
		Handle => $connected_socket,
		Driver => POE::Driver::SysRW->new(),
		Filter => POE::Filter::Reference->new($yaml),
		InputEvent => 'socket_rcvd_input',
		ErrorEvent => 'socket_death',
	);
#	my $send = ["welcome","HAE TS Node Designation.",0];
	my $send = {'state'=>"welcome",'mess'=>$init_server_message,'key'=>0};
	$heap->{socket_wheel}->put($send);
}
sub socket_rcvd_input {
	my ($heap, $kernel, $buffer) = @_[HEAP, KERNEL, ARG0];

	if(exists $buffer->{state}) {
		if(!$buffer->{state}) {
			####
			## if client fails to close and sends a null response...force connection closed
			####
			print "client is null...forcing connection closed.\n";
			$kernel->yield("socket_death");
			return;
		} elsif($buffer->{state}=~/^[Qq]$|^quit/i) {
			print "stop requested!\n";

			my $send = {};
			$send->{state} = 'stop_requested';
			$send->{status} = 1;
			$send->{mess} = 'stopping server';
			$send->{nskey} = $buffer->{nskey};
			if(exists $buffer->{save}) {
				# ...should put something here :)
				$send->{save} = 'no stinkin save!';
			}
			$k_count = 0;
			$kill_session = 0;
			$kernel->delay(wait_kill => 5);
			$heap->{socket_wheel}->put($send);
			return;
		} elsif($buffer->{state}=~/^close/i) {
			print "closing connection...\n";
			$kernel->yield("socket_death");
			return;
		} elsif($buffer->{state}=~/^restart/i) {
			print "Restarting listener...\n";
			$kernel->yield("listener_restart");
			return;
		} elsif($buffer->{state}=~/^heart/i) {
			print "= [$my_shortform_server_type] = Heartbeat received[".$buffer->{heartbeat}."], sending pulse back \n" if $testing;
			my $send = {};
			$send->{state} = 'heartbeat';
			if(exists $buffer->{server_key} && $testing) {
				print "\t++ from server [".$buffer->{server_key}."]\n";
				$send->{server_key} = $buffer->{server_key};
			}
			$send->{heartbeat} = $buffer->{heartbeat} + 1;
			$send->{pulse} = "uptime[".localtime()."]";
			$send->{mess} = $whoami . ":" . $my_server_address . ":" . $my_server_port . ":alive and ticking";
			$send->{status} = 1;
			$send->{client_signal} = $buffer->{client_signal};
			$heap->{socket_wheel}->put($send);
			return;
		} elsif($buffer->{state}=~/^pulse/i) {
			print "= [$my_shortform_server_type] = Pulse received[".$buffer->{pulse}."], sending pulse back \n" if $testing;
			my $send = {};
			$send->{state} = 'pulse';
			$send->{status} = 1;
			$send->{pulse} = $buffer->{pulse} + 1;
			$send->{mess} = 0;
			$heap->{socket_wheel}->put($send);
			return;
###############################################################
		} elsif($buffer->{state}=~/^run_codes/i) {
			print "= [$my_shortform_server_type] = State received[".$buffer->{state}."]\n" if $trace;
			my $type = 1;
			if(defined $buffer->{type}) {
				$type = $buffer->{type}; 
			}
			my $send = &run_data_coding($type,$buffer);
			$heap->{socket_wheel}->put($send);
			return;
			
		} else {
			print "= [$my_shortform_server_type] = submitted state[".$buffer->{state}."] not recognized\n" if $testing;
			my $send = {};
			$send->{state} = 'error_state';
			$send->{status} = 0;
			$send->{mess} = "submitted state[".$buffer->{state}."] not recognized";
			$heap->{socket_wheel}->put($send);
			return;
		}
	} else {
		my $send = no_client_registration();
		$heap->{socket_wheel}->put($send);
		return 1;
	}
}

sub no_client_registration {
	my $s = {};
	$s->{key} = 0;
	$s->{num} = 0;
	$s->{mess} = "georgia rainy runs";
	$s->{state} = 'hae grr';
	return $s;
}

sub set_registration {
	my $heap = shift;
	my $loc_buffer = shift;
	my $eserver = $loc_buffer->{client_name};
	my $event_code = $loc_buffer->{event_code};
	my $nid = $node * 1000;
	return ($nid);
}
sub run_data_coding {
	my ($type,$input) = @_;

	my $trace = $run_codes_trace;
	my $acting = '-file parsing';
	if($type==10) {
		## run file parse
		$acting = '-re coding';
		print "= [$my_shortform_server_type] = type[$type] data $acting\n" if $trace;
	}
	if($type==1) {
		## run file parse
		print "= [$my_shortform_server_type] = type[$type] data $acting\n" if $trace;
	}
	if($type==3) {
		$acting = '-parting & piecing';
		print "= [$my_shortform_server_type] = type[$type] data $acting\n" if $trace;
	}
	if($type==5) {
		$acting = '-set topic codes';
		print "= [$my_shortform_server_type] = type[$type] code $acting\n" if $trace;
	}
	if($type==7) {
		$acting = '-clean recode markup';
		print "= [$my_shortform_server_type] = type[$type] code $acting\n" if $trace;
	}
	if($type==8) {
		$acting = '-make recode stats';
		print "= [$my_shortform_server_type] = type[$type] code $acting\n" if $trace;
	}
	if($type==9) {
		print "= [$my_shortform_server_type] = type[$type] aco data file writing\n" if $trace;
	}
	if($type==11) {
		print "= [$my_shortform_server_type] = type[$type] aspect distance calc\n" if $trace;
	}
	if($type==12) {
		print "= [$my_shortform_server_type] = type[$type] code linkage distance calc\n" if $trace;
	}
	if($type==14) {
		print "= [$my_shortform_server_type] = type[$type] write code stats to spreadsheets\n" if $trace;
	}

	foreach my $key (keys %$input) {
		print "  run_data_coding - input param [$key] val[".$input->{$key}."]\n" if $trace;
	}

	my $send = {};
	$send->{state} = 'task_confirm';
	$send->{sent_state} = $input->{state};
	$send->{status} = 1;
	$send->{mess} = "run coding, type[".$type."] [";
	if(exists $work_type->{$type}) {
		$send->{mess} = $send->{mess} . $work_type->{$type};
	}
	$send->{mess} = $send->{mess} . "]";
	my $task_id = 0;
	if(exists $input->{task_id}) {
		$task_id = $send->{task_id} = $input->{task_id};
	}

	my $success = 1;
	if(!defined $data_coding) {
		$data_coding = {};
	}
	
	if($type==1) {
		$success = &code_files_mgr($type,$task_id,$trace);
		$send->{mess} = $send->{mess} . " parsed files";
	}
	if($type==3) {
		$success = &code_files_mgr($type,$task_id,$trace);
		$send->{mess} = $send->{mess} . " parsed topics";
	}
	if($type==5) {
		$success = &code_files_mgr($type,$task_id,$trace);
		$send->{mess} = $send->{mess} . " set prelim codes";
	}
	if($type==7) {
		$codes_dirty->{will_make_data_coding_mods} = 1;
		$success = &re_code_sco_files($type,$task_id,$trace);
		if($success) {
			$send->{mess} = $send->{mess} . " clean recode markup";
		} else {
			$send->{mess} = $send->{mess} . " " . $codes_dirty->{__ERROR__}; 
		}
	}
	if($type==8) {
		$success = &re_code_sco_files($type,$task_id,$trace);
		if($success) {
			$send->{mess} = $send->{mess} . " made recode stats";
		} else {
			$send->{mess} = $send->{mess} . " " . $codes_dirty->{__ERROR__}; 
		}
	}
	if($type==9) {
		$success = &write_files_mgr($type,$task_id,$trace);
		$send->{mess} = $send->{mess} . " (almost) wrote atx and txt files";
	}
	if($type==11) {
		$run_status->{codes_are_new_for_coding} = 1;
		$success = &calc_aspects($type,$task_id,$trace);
		$send->{mess} = $send->{mess} . "aspect calc";
	}
	if($type==12) {
		$run_status->{codes_are_new_for_coding} = 1;
		$success = &calc_code_dist($type,$task_id,$trace);
		$send->{mess} = $send->{mess} . "dist calc";
	}
	if($type==14) {
		$success = &write_code_stats_xls($type,$task_id,$trace);
		if(!$success) {
			$send->{mess} = $send->{mess} . "!! write failure to sheets";
		} else {
			$send->{mess} = $send->{mess} . "stats";
		}
	}
	if($type==10) {
		
		$success = &re_code_sco_files(1,$task_id,$trace);

	}

	if(defined $run_status and scalar(keys %$run_status)) {
		my $ddir = $dir . $yml_dir;
		&dump_coding_to_yml($run_status,$ddir,$runstatusfile,$trace);
	}

	if(!$success) {
		$send->{status} = 0;
		return $send;
	}
	
	say "End of parsing...bye, bye";
	return $send;
}

sub code_files_mgr {
	my ($cat,$task_id,$trace) = @_;
	print "= [$my_shortform_server_type][$task_id] = parse files; manage cat[$cat] parsing\n" if $trace;
	
	if($cat==1) {
		my $done = &parse_txt_files($cat,$task_id,$trace);
		if($done) { $run_status->{parse_is_new_for_coding} = 1; }
	}
	if($cat==3) {
		my $done = &find_codes($cat,$task_id,$trace);
		if($done) { $run_status->{parts_are_new_for_coding} = 1; }
	}
	if($cat==5) {
		my $done = &find_codes($cat,$task_id,$trace);
		if(exists $run_status->{parse_is_new_for_coding} and $run_status->{parse_is_new_for_coding}) {
			if(!exists $run_status->{parts_are_new_for_coding} or !$run_status->{parts_are_new_for_coding}) {
				die "\tout of order execution of methods as line {".__LINE__."}\n";
			}
			$codes_dirty->{will_make_data_coding_mods} = 1;
		}
		if(exists $run_status->{parts_are_new_for_coding} and $run_status->{parts_are_new_for_coding}) {
			$codes_dirty->{will_make_data_coding_mods} = 1;
		}
		if($done) { $run_status->{codes_are_new_for_coding} = 1; }
	}
	return $task_id;
}
sub re_code_sco_files {
	my ($cat,$taskid,$trace) = @_;
	my $me = "POST-RECODE";
	$me = $me . "][taskid:$taskid][cat:$cat";
	print "= [$my_shortform_server_type][$me] manage re-codes\n" if $trace;

	my $trace_more = 0;
	
	my $ddir = $dir . $yml_dir;
	my $rdir = $dir;
	my $backed_up = 0;
	if(defined $data_coding and scalar(keys %$data_coding)) {
		## check for previous session use of data_coding, if not, assume a backup copy needs to be made
		if(exists $codes_dirty->{will_make_data_coding_mods} and $codes_dirty->{will_make_data_coding_mods}) {
			## save old parse to a backup file
			my $bakfile = $codingfilenam . "_" . $dtg . ".yml";
			&dump_recovery_file_to_yml($data_coding,$rdir,$bakfile,$trace);
			$codes_dirty->{will_make_data_coding_mods} = 0;
			$codes_dirty->{will_make_data_coding_stats} = 1;
			$backed_up = 1;
		}
	}
	if(!defined $data_post_coding) {
		$data_post_coding = {};
	}
	if(scalar(keys %$data_post_coding)) {
		## check for previous session use of data_coding, if not, assume a backup copy needs to be made
		if(exists $codes_dirty->{will_make_data_coding_stats} and $codes_dirty->{will_make_data_coding_stats}) {
			## save old parse to a backup file
			my $bakfile = $postcodingfilenam . "_" . $dtg . ".yml";
			&dump_recovery_file_to_yml($data_post_coding,$rdir,$bakfile,$trace);
			$codes_dirty->{will_make_data_coding_stats} = 0;
		}
	}

	my $clean_hash_keys = 0;
	if(exists $run_status->{clean_hash_keys}and $run_status->{clean_hash_keys}) {
		$clean_hash_keys = 1;
	}
	
	my $rctr = 0;
	my $cln_ctr = 0;
	if($cat==7) {
		####
		## NOTE: this is assumed to be post data coder...all re-codes are completed
		## make code stats based on sentence info (chars, words, count of sentences per code, etc.)
		## updates to data_postparse, post_coding will be done based on previous parse changes
		## per run_status value
		## results are stashed in data_postparse
		####
		print "[$my_shortform_server_type][$me] CLEAN -- active inames[".scalar(keys %{ $run_status->{active_3_done_precoding_iname} })."] for cleaning\n" if $trace;

		if(!$backed_up) {
			## save old parse to a backup file
			my $bakfile = $codingfilenam . "_" . $dtg . ".yml";
			&dump_recovery_file_to_yml($data_coding,$rdir,$bakfile,$trace);
			$codes_dirty->{will_make_data_coding_mods} = 0;
			$backed_up = 1;
		}

		if(defined $data_coding->{runlinks}->{name_codes} and scalar(keys %{ $data_coding->{runlinks}->{name_codes} })) {
			foreach my $iname (keys %{ $data_coding->{runlinks}->{name_codes} }) {
				my $ct = 0;
				if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats} and $data_post_coding->{post_coding}->{$iname}->{code_stats}=~/HASH/) {
					$ct = scalar(keys %{ $data_post_coding->{post_coding}->{$iname}->{code_stats} });
				}
				my $out = $ct;
				if(!$ct) { $out = 'NONE'; }
				say "[$my_shortform_server_type][$me] iname[$iname] post_code stats check, count[".$ct."]";
			}
		}
	
		if(exists $run_status->{post_code_all_inames_TOGG} and $run_status->{post_code_all_inames_TOGG}) {
		
			my $fail = 0;
			print "[$my_shortform_server_type][$me] clean codes for all inames, ct[".scalar(keys %{ $data_coding->{runlinks}->{name_codes} })."]\n" if $trace;
			if(defined $data_coding->{runlinks}->{name_codes} and scalar(keys %{ $data_coding->{runlinks}->{name_codes} })) {
				foreach my $iname (keys %{ $run_status->{active_3_done_precoding_iname} }) {
#					if(exists $run_status->{active_4_needs_clean_coding_iname} and $run_status->{active_4_needs_clean_coding_iname} and $run_status->{active_coding_iname_verify}->{$iname}) {
					if(exists $run_status->{verify_sentences_parsing_coding} and $run_status->{verify_sentences_parsing_coding}) {
						print "[$my_shortform_server_type][$me] CLEAN codes for iname[".$iname."]\n" if $trace;
						my $success = &clean_post_recode_data($taskid,$iname,$clean_hash_keys,$trace,$trace_more);
						if($success) {
							$cln_ctr++;
							$codes_dirty->{re_codes} = 1;
							$run_status->{active_4_done_clean_coding_iname}->{$iname} = 1;
							$run_status->{active_4_needs_clean_coding_iname}->{$iname} = 0;
							$run_status->{active_5_needs_code_stating_iname}->{$iname} = 1;
						} else {
							if(!exists $codes_dirty->{__ERROR__}) {
								$codes_dirty->{__ERROR__} = 'CLEAN ERROR:';
							}
							$codes_dirty->{__ERROR__} = $codes_dirty->{__ERROR__} . " [" . $iname . ":Fail]"; 
							$fail = 1;
						}
					}
				}
			}
			if($fail) { return 0; }
#			die "\t\tstopping here\n";
			


		} else {
			my $fail = 0;
			foreach my $iname (keys %{ $run_status->{post_coding_iname_verify_TOG_ON} }) {
				if($run_status->{post_coding_iname_verify_TOG_ON}->{$iname}) {
				
					if(scalar(keys %$final_codectrhref)) {
						## clear the codectrhref array
						$final_codectrhref = undef;
						$final_codectrhref = {};
					}

					print "= [$my_shortform_server_type][$me] clean codes for iname[".$iname."]\n" if $trace;
					my $success = &clean_post_recode_data($taskid,$iname,$clean_hash_keys,$trace,$trace_more);
					if($success) {
						$codes_dirty->{re_codes} = 1;
						$cln_ctr++;
						$run_status->{active_4_done_clean_coding_iname}->{$iname} = 1;
						$run_status->{active_4_needs_clean_coding_iname}->{$iname} = 0;
						$run_status->{active_5_needs_code_stating_iname}->{$iname} = 1;
					} else {
						if(!exists $codes_dirty->{__ERROR__}) {
							$codes_dirty->{__ERROR__} = 'CLEAN ERROR:';
						}
						$codes_dirty->{__ERROR__} = $codes_dirty->{__ERROR__} . " [" . $iname . ":Fail]"; 
						$fail = 1;
					}
				}
			}
		}
		$run_status->{state_coding} = 3;
		$run_status->{state_coding_info} = 'clean re-code markup';
		$run_status->{last_code_clean_dtg} = $dtg;
		$run_status->{recode_clean_inames}->{count} = $rctr;
		
			
	} elsif($cat==8) {

#		foreach my $iname (keys %{ $run_status->{active_coding_iname_makestats} }) {
#			if($run_status->{active_coding_iname_makestats}->{$iname}) {
#				print "= [$my_shortform_server_type][$me] make code stats for iname[".$iname."]\n" if $trace;
#				my $success = &make_post_recode_stats($taskid,$iname,$clean_hash_keys,$trace,$trace_more);
#				if($success) {
#					$rctr++;
#				}
#			}
#		}
		print "= [$my_shortform_server_type][$me] make code stats for all inames, ct[".scalar(keys %{ $data_coding->{runlinks}->{name_codes} })."]\n" if $trace;

		## clear all previous meta_coding...assume reconstruction is better...
#		$data_post_coding->{aquad_meta_coding}->{all_inames} = undef;
		$data_post_coding = {};
		
		if(defined $data_coding->{runlinks}->{name_codes} and scalar(keys %{ $data_coding->{runlinks}->{name_codes} })) {
			foreach my $iname (keys %{ $run_status->{active_4_done_clean_coding_iname} }) {
#			foreach my $iname (keys %{ $data_coding->{runlinks}->{name_codes} }) {
				if($data_coding->{runlinks}->{name_codes}->{$iname}) {
					## this iname is toggled on...use
					my $success = &make_post_recode_stats($taskid,$iname,$clean_hash_keys,$trace,$trace_more);
					if($success) {
						$codes_dirty->{re_codes} = 1;
						$rctr++;
						$run_status->{active_5_needs_code_stating_iname}->{$iname} = 0;
						$run_status->{active_5_done_code_stating_iname}->{$iname} = 1;
						$run_status->{active_6_needs_code_calc_iname}->{$iname} = 1;
					}
				}
			}
		}
		&make_summary_post_recode_stats($taskid,$trace,$trace_more);

#		$run_status->{active_4_done_clean_coding_iname}->{$iname} = 1;
#		$run_status->{active_4_needs_clean_coding_iname}->{$iname} = 0;
		

		$run_status->{state_coding} = 4;
		$run_status->{state_coding_info} = 're-code stats made';
		$run_status->{last_code_stats_dtg} = $dtg;
		$run_status->{recode_stats_inames}->{count} = $rctr;
		
		if(defined $data_coding->{runlinks}->{name_codes} and scalar(keys %{ $data_coding->{runlinks}->{name_codes} })) {
			foreach my $iname (keys %{ $data_coding->{runlinks}->{name_codes} }) {
				say "[$my_shortform_server_type][$me] iname[$iname] code ct[".scalar(keys %{ $data_post_coding->{post_coding}->{$iname}->{code_stats} })."]";
			}
		}

	} else {
		print "= [$my_shortform_server_type][$me] this function is broke\n" if $trace;
		die "\tdying to fix\n";

		foreach my $topkey (keys %$data_coding) {
			say "\ttopkey[$topkey] v[".$data_coding->{$topkey}."]";
		
			if(exists $data_coding->{$topkey}->{re_codes}) {
				say "\t\tre_codes exist for [$topkey] v[".$data_coding->{$topkey}->{re_codes}."] sent ct[".scalar(keys %{ $data_coding->{$topkey}->{re_codes}->{sentences} })."]";
				my $file_codes = $data_coding->{$topkey}->{re_codes};
				my $name = $data_coding->{$topkey}->{profile}->{files}->{root_name};
	#			$name = lc $name;
				my $str = &make_sentence_aco_file($file_codes,$topkey,$taskid,$trace);

				if(!exists $write_these_files->{do_these}->{$topkey}) {
					## skip
					next;
				}

				my $f = "{s- cS}" . $name . ".atx";
				my $tf = $name . ".txt";
				my $atf = $name . ".atx";
				my $acof = $name . "_2.aco";
				my $test_dir = "server_test/";
	#			$acof = $test_dir . $acof;
				my $ddir = $dir . $recod_dir;
				$acof = $ddir . $acof;
				open ACOFILE, ">$acof" or die $!;
				print ACOFILE $str;
				print "Wrote aco text file [$acof] for [".length($str)."] chars data\n" if $trace;
				close ACOFILE;

				$rctr++;
			}
		}
		$run_status->{state_coding} = 3;
		$run_status->{state_coding_info} = 'sentence re-codes to aco';
		$run_status->{last_code_file_dtg} = $dtg;
	}
	if(exists $codes_dirty->{freq_codes} and $codes_dirty->{freq_codes}) {
		##	make_amc_file
		foreach my $topkey (keys %$data_coding) {
			if(!exists $write_these_files->{do_these}->{$topkey}) {
				## skip
				next;
			}
			say "\t\t[taskid:$taskid] making code freq file for [$topkey] v[".$data_coding->{$topkey}->{re_codes}."] " if $trace;
			my $str = &make_amc_file($topkey,$taskid,$trace);
			my $f = "project1.amc";
			my $ddir = $dir . $recod_dir;
			say "[$my_shortform_server_type][$taskid] iname[$topkey] amc filename [$f]";
			&dump_str_to_file($str,$ddir,$f,$topkey,$trace);
		}
	}
	if(exists $codes_dirty->{re_codes} and $codes_dirty->{re_codes}) {
		if(!defined $data_coding) {
			die "CODE FAIL! fix your mess.";
		}

		## updates to data codes 
		my $ddir = $dir . $yml_dir;
		if(scalar(keys %$data_coding)) {
			&dump_coding_to_yml($data_coding,$ddir,$codingfile,$trace);
		}

		$codes_dirty->{re_codes} = 0;
	}
	if(exists $codes_dirty->{post_parse} and $codes_dirty->{post_parse}) {
		if(!defined $data_postparse) {
			die "CODE FAIL! no *data_postparse* hash .... fix your mess.";
		}
		my $ddir = $dir . $yml_dir;

		## don't wipe out your data file :)....
		if(scalar(keys $data_postparse)) {
			&dump_coding_to_yml($data_postparse,$ddir,$postparsefile,$trace);
		}
		$codes_dirty->{post_parse} = 0;
	}
	if(exists $codes_dirty->{post_coding} and $codes_dirty->{post_coding}) {
		if(!defined $data_post_coding) {
			die "CODE FAIL! no *data_post_coding* hash .... fix your mess.";
		}
		my $ddir = $dir . $yml_dir;
		if(scalar(keys $data_post_coding)) {
			&dump_coding_to_yml($data_post_coding,$ddir,$postcodingfile,$trace);
		}
		$codes_dirty->{post_coding} = 0;
	}
		

	$run_status->{re_coded_inames}->{count} = $rctr;


	return $taskid;
}
sub write_files_mgr {
	my ($cat,$task_id,$trace) = @_;
	print "= [$my_shortform_server_type][$task_id] = write files mgr; manage cat[$cat] coding\n" if $trace;
	if(!defined $data_parsing or !scalar(keys %$data_parsing)) {
		print "= [$my_shortform_server_type][$task_id] BAD result! No data to code in *data_parsing* var\n" if $runtime;
		return 0;
	}
	
	my $skip_first = 0;
	if($skip_first_line_in_parsed_data) {
		$skip_first = 1;
	}

	my $rctr = 0;
	if($cat==7) {
		my $fdata_href = {};
		my $atxdata_href = {};
		my $txtdata_href = {};
		my $txt2data_href = {};
		foreach my $iname (keys %{ $data_postparse->{aquad_meta_parse}->{name_codes} }) {
			if(!exists $data_postparse->{post_parse}->{$iname}) {
				## skip
				next;
			}
			say "[$my_shortform_server_type][$task_id] iname[$iname] attempting to make atx file";
			$fdata_href->{$iname} = &make_s_cS_file($cat,$task_id,$iname,$skip_first,$trace);
			say "[$my_shortform_server_type][$task_id] iname[$iname] s_cS file size [".length($fdata_href->{$iname})."]";
			$atxdata_href->{$iname} = &make_atx_file($cat,$task_id,$iname,$trace);
			say "[$my_shortform_server_type][$task_id] iname[$iname] atx file size [".length($atxdata_href->{$iname})."]";
			$txtdata_href->{$iname} = &make_txt_file($cat,$task_id,$iname,$trace);
			say "[$my_shortform_server_type][$task_id] iname[$iname] txt file size [".length($txtdata_href->{$iname})."]";
			$txt2data_href->{$iname} = &make_txt2_file($cat,$task_id,$iname,$skip_first,$trace);
			
		}

		####
		## Create per Name files:
		##  .txt file - base reference text file (<500 chars per line)
		##  .atx file - sentence-based text file (<500 chars per line)
		##  s_cS file - numbered sentence-based line file (<500 chars per line)
		##
		####
#		my $ddir = $dir . $recod_dir;
		my $ddir = $dir . $atx_txt_dir;
		my @nam = ();
		my @nam2 = ();
		my @nam3 = ();
		my @nam4 = ();
		foreach my $iname (keys %{ $data_postparse->{aquad_meta_parse}->{name_codes} }) {
			if(!exists $write_these_files->{do_these}->{$iname}) {
				## skip
				next;
			}
			my $filenam = $data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{name_no_ext};
			my $scsf = "{s- cS}" . $filenam . ".atx";
			my $tf = $filenam . ".txt";
			my $atf = $filenam . ".atx";
			my $t2f = $filenam . "_2.txt";
#			my $acof = $filenam . ".aco";

			## s_cS file
			say "[$my_shortform_server_type][$task_id] iname[$iname] s_cS filename [$scsf]";
			&dump_str_to_file($fdata_href->{$iname},$ddir,$scsf,$iname,$trace);
			push @nam,$scsf;
			## atx file
			say "[$my_shortform_server_type][$task_id] iname[$iname] atx filename [$atf]";
			&dump_str_to_file($atxdata_href->{$iname},$ddir,$atf,$iname,$trace);
			push @nam2,$atf;
			## txt file
			say "[$my_shortform_server_type][$task_id] iname[$iname] txt filename [$tf]";
			&dump_str_to_file($txtdata_href->{$iname},$ddir,$tf,$iname,$trace);
			push @nam3,$tf;
			say "[$my_shortform_server_type][$task_id] iname[$iname] txt2 filename [$t2f]";
			&dump_str_to_file($txt2data_href->{$iname},$ddir,$t2f,$iname,$trace);
			push @nam4,$tf;
		}

		####
		## Create:
		##  dissertation.nam - names of parsed text-line files
		##  aqd7{mem.fil - names of source text files
		##  {S_Analysis} - names of text files in atx form (pure text with atx extended)
		##
		##  copy over starting text files to .atx
		####

		my $loop = 1;
		my $filetxt = '';
		while($loop) {
			if(scalar(@nam)) {
				my $name = shift @nam;
				if(!$filetxt) {
					$filetxt = $name;
					next;
				}
				$filetxt = $filetxt . "\n" . $name;
				next;
			}
			$loop = 0;
		}
		my $pfile = $project_name . ".nam";
		if($filetxt) {
			&dump_str_to_file($filetxt,$ddir,$pfile,'list',$trace);
		}
		$loop = 1;
		$filetxt = '';
		while($loop) {
			if(scalar(@nam2)) {
				my $name = shift @nam2;
				if(!$filetxt) {
					$filetxt = $name;
					next;
				}
				$filetxt = $filetxt . "\n" . $name;
				next;
			}
			$loop = 0;
		}
		my $rctr = scalar(@nam2);
		
		my $anafile = "{S_Analysis}";
		if($filetxt) {
			&dump_str_to_file($filetxt,$ddir,$anafile,'list',$trace);
		}
		$loop = 1;
		$filetxt = '';
		while($loop) {
			if(scalar(@nam3)) {
				my $name = shift @nam3;
				if(!$filetxt) {
					$filetxt = $name;
					next;
				}
				$filetxt = $filetxt . "\n" . $name;
				next;
			}
			$loop = 0;
		}
		my $memfile = "aqd7{mem.fil";
		if($filetxt) {
			&dump_str_to_file($filetxt,$ddir,$memfile,'list',$trace);
		}

	}

	$run_status->{state_parse} = 3;
	$run_status->{state_parse_info} = 'created atx and txt files';
	$run_status->{last_file_dtg} = $dtg;
	$run_status->{atx_files}->{count} = $rctr;

	return $task_id;
}
sub write_code_stats_xls {
	my ($cat,$task_id,$trace) = @_;
	my $me = "MGR-WRITE-XLS";
	$me = $me . "][taskid:$task_id][cat:$cat";
	print "= [$my_shortform_server_type][$me] = write code stats to spreadsheets; cat[$cat]\n" if $trace;
	
	if(!defined $data_stats) {
		my $file = $dir . $yml_dir . $statsfile;
		say "[XLS][taskid:$task_id] Stats NOT loaded, reloading Stats file[$statsfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_stats = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
		if(defined $data_stats and scalar(keys %$data_stats)) {
			say "[XLS][taskid:$task_id] Stats reloaded; key ct[".scalar(keys %{$data_stats})."]" if $trace;
			foreach my $key (keys %{$data_stats}) {
				say "\tTop key [$key] option ct[".scalar(keys %{$data_stats->{$key}})."] " if $trace;
				if($key=~/^by_iname$/i) {
					say "\t\t[$key] by_name ct[".scalar(keys %{$data_stats->{by_name}})."] " if $trace;
				}
			}
		}
	}
	my $statcodes = $data_stats->{by_iname};
	if(!defined $data_stats_2x) {
		my $file = $dir . $yml_dir . $stats2xfile;
#		say "[XLS][taskid:$task_id] Stats2x NOT loaded, reloading 2xStats file[$stats2xfile]...this may take a moment..." if $trace;
#		if(open(my $fh, '<', $file)) {
#			$data_stats_2x = LoadFile($file);
#		} else {
#			die "\nERROR! cannot open [$file] [$!]";
#		}
		if(defined $data_stats_2x and scalar(keys %$data_stats_2x)) {
			say "[XLS][taskid:$task_id] Stats reloaded; key ct[".scalar(keys %{$data_stats_2x})."]" if $trace;
			foreach my $key (keys %{$data_stats_2x}) {
				say "\tTop key [$key] option ct[".scalar(keys %{$data_stats_2x->{$key}})."] " if $trace;
				if($key=~/^by_iname$/i) {
					say "\t\t[$key] by_name ct[".scalar(keys %{$data_stats_2x->{by_name}})."] " if $trace;
				}
			}
		}
	}
	my $statcodes2x = $data_stats_2x->{by_iname};
	if(!defined $data_stats_aspects) {
		my $file = $dir . $yml_dir . $statsaspectsfile;
		say "[XLS][taskid:$task_id] Stats NOT loaded, reloading Stats file[$statsaspectsfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_stats_aspects = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
		if(defined $data_stats_aspects and scalar(keys %$data_stats_aspects)) {
			say "[XLS][taskid:$task_id] Stats reloaded; key ct[".scalar(keys %{$data_stats_aspects})."]" if $trace;
			foreach my $key (keys %{$data_stats_aspects}) {
				say "\tTop key [$key] option ct[".scalar(keys %{$data_stats_aspects->{$key}})."] " if $trace;
				if($key=~/^by_iname$/i) {
					say "\t\t[$key] by_name ct[".scalar(keys %{$data_stats_aspects->{by_name}})."] " if $trace;
				}
			}
		}
	}
	if(!exists $data_stats_aspects->{by_iname}) {
		say "[$my_shortform_server_type][$me] Critical Failure writing criticals....missing hash[data_stats_aspects] or hashkey{by_iname}";
		die "\tdying to fix, line[".__LINE__."]\n";
	}
	my $stat_aspects = $data_stats_aspects->{by_iname};
	if(!defined $data_stats_linkage) {
		my $file = $dir . $yml_dir . $statslinkfile;
#		say "[XLS][taskid:$task_id] Stats Linkage NOT loaded, reloading Stats Linkage file[$statslinkfile]...this may take a moment..." if $trace;
#		if(open(my $fh, '<', $file)) {
#			$data_stats_linkage = LoadFile($file);
#		} else {
#			die "\nERROR! cannot open [$file] [$!]";
#		}
		if(defined $data_stats_linkage and scalar(keys %$data_stats_linkage)) {
			say "[XLS][taskid:$task_id] Stats LINKAGE reloaded; key ct[".scalar(keys %{$data_stats_linkage})."]" if $trace;
			foreach my $key (keys %{$data_stats_aspects}) {
				say "\tTop key [$key] option ct[".scalar(keys %{$data_stats_linkage->{$key}})."] " if $trace;
				if($key=~/^by_iname$/i) {
					say "\t\t[$key] by_name ct[".scalar(keys %{$data_stats_linkage->{by_name}})."] " if $trace;
				}
			}
		}
	}
#	if(!exists $data_stats_linkage->{by_iname}) {
#		say "[$my_shortform_server_type][$me] Critical Failure loading stats linkage file...missing hash[data_stats_linkage] or hashkey{by_iname}";
#		die "\tdying to fix, line[".__LINE__."]\n";
#	}
	my $statlinks = $data_stats_linkage->{by_iname};
	if(!defined $stats_base_disp) {
		my $file = $dir . $yml_dir . $stats_basefile;
		say "[$me] Base Stats V2 NOT loaded, reloading base stats file[$stats_basefile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$stats_base_disp = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
		if(defined $stats_base_disp and scalar(keys %$stats_base_disp)) {
			say "[XLS][taskid:$task_id] BASE Stats reloaded; key ct[".scalar(keys %{$stats_base_disp})."]" if $trace;
			foreach my $key (keys %{$stats_base_disp}) {
				say "\tTop key [$key] option ct[".scalar(keys %{$stats_base_disp->{$key}})."] " if $trace;
				if($key=~/^by_iname$/i) {
					say "\t\t[$key] by_name ct[".scalar(keys %{$stats_base_disp->{by_name}})."] " if $trace;
				}
			}
		}
	}

	# Create a new Excel workbook
#	my $filename = $tatssheetsfile . ".xls"; ...old
	my $filename = $tatssheetsfile . ".xlsx";
	my $ddir = $dir . $yml_dir;
	$filename = $ddir . $filename;
#	my $workbook  = Spreadsheet::WriteExcel->new( $filename );
	my $workbook = Excel::Writer::XLSX->new( $filename );
	if(!defined $workbook) {
		warn "[cat:$cat][taskid:$task_id] WARNING! Not able to open file[$filename] ... may be in use??";
		return 0;
	}


	# Add some worksheets
	my $per_code_sheet = $workbook->add_worksheet("all_code_stats");
	my $main_code_sheet = $workbook->add_worksheet("main_code_stats");
	my $nested_code_sheet = $workbook->add_worksheet("nested_code_stats");
	my $nested_code_short_sheet = $workbook->add_worksheet("nested_code_short_stats");
#	my $linkage_sheet = $workbook->add_worksheet("code_linkages");
#	my $nested_sheet = $workbook->add_worksheet("nested_codes");
	my $dispersion_cluster_sheet = $workbook->add_worksheet("dispersion_clustering");
#	my $x2_groups_sheet = $workbook->add_worksheet("two_code_grouping");
	my $aspect_info_sheet = $workbook->add_worksheet("aspect_info");
	my $aspect_critical_sheet = $workbook->add_worksheet("critical_texts");
##	my $aspect_topic_cluster_sheet  = $workbook->add_worksheet("aspect_topic_clusters");
#	my $aspect_linkage_sheet = $workbook->add_worksheet("aspect2code_linkages");
#	my $topic_cluster_sheet  = $workbook->add_worksheet("code_topic_clusters");
#	my $x2_dispersion_sheet = $workbook->add_worksheet("two_code_dispersion");

	# Add a Format
	my $format = $workbook->add_format();
	$format->set_bold();
	$format->set_color('blue');
	# Some common formats
	my $center  = $workbook->add_format(align => 'center');
	my $heading = $workbook->add_format(align => 'center', bold => 1);
	my $heading2 = $workbook->add_format(align => 'left', bold => 1);
	my $blueheading = $workbook->add_format(align => 'center', bold => 1);
	$blueheading->set_color('blue');
	my $shade_format = $workbook->add_format(align => 'center', bold => 1, bg_color => 'pink', pattern => 1, border => 1);

	my $iname = 'K0T0';

	my $option = 0;
	&write_per_code_tables($cat,$task_id,$option,$per_code_sheet,$statcodes,$heading,$heading2,$center,$trace);
	&write_aspect_criticals_tables($cat,$task_id,$option,$aspect_info_sheet,$stat_aspects,$heading,$heading2,$center,$shade_format,$trace);
	&write_nested_code_tables($cat,$task_id,$option,$nested_code_sheet,$statcodes,$heading,$heading2,$center,$trace);
	&write_dispersion_clustering($cat,$task_id,$option,$dispersion_cluster_sheet,$center,$heading,$format,$shade_format,$trace);

	$option = 1;
	&write_per_code_tables($cat,$task_id,$option,$main_code_sheet,$statcodes,$heading,$heading2,$center,$trace);
	&write_aspect_criticals_tables($cat,$task_id,$option,$aspect_critical_sheet,$stat_aspects,$heading,$heading2,$center,$shade_format,$trace);
	&write_nested_code_tables($cat,$task_id,$option,$nested_code_short_sheet,$statcodes,$heading,$heading2,$center,$trace);

	
#	&write_topic_clustering($cat,$task_id,$iname,$topic_cluster_sheet,$statcodes,$heading,$format,$shade_format,$trace);
	 
#	&write_linkage_updown_ranked($cat,$task_id,$linkage_sheet,$statcodes,$heading,$heading2,$center,$shade_format,$trace);
#	&write_nested_updown($cat,$task_id,$nested_sheet,$statcodes,$heading,$heading2,$center,$shade_format,$trace);

#	my ($code_cont,$cont_map) = &write_dispersion_2x($cat,$task_id,$x2_dispersion_sheet,$statcodes2x,$heading,$heading2,$center,$shade_format,$trace);

#	&write_2x_code_groups($cat,$task_id,$x2_groups_sheet,$code_cont,$cont_map,$heading,$heading2,$center,$shade_format,$trace);

#	&write_aspect_linkage_updown($cat,$task_id,$iname,$aspect_linkage_sheet,$statcodes,$heading,$format,$shade_format,$trace);
	

#	&write_linkage_updown($cat,$task_id,$iname,$linkage_sheet,$statcodes,$heading,$format,$shade_format,$trace);
#	&write_topic_aspect_clustering($cat,$task_id,$iname,$aspect_topic_cluster_sheet,$statcodes,$heading,$format,$shade_format,$trace);
#	&write_aspect_criticals($cat,$task_id,$iname,$aspect_critical_sheet,$statcodes,$heading,$center,$shade_format,$trace);
	
	# Set the active worksheet
	$per_code_sheet->activate();

	
	# Note: this is required to write the file to disk
	$workbook->close();

	if(exists $codes_dirty->{re_codes} and $codes_dirty->{re_codes}) {
		if(!defined $data_coding) {
			die "CODE FAIL! fix your mess.";
		}

		## this may be triggered by updates to base codes...
		my $ddir = $dir . $yml_dir;
		if(scalar(keys %$data_coding)) {
			&dump_coding_to_yml($data_coding,$ddir,$codingfile,$trace);
		}

		$codes_dirty->{re_codes} = 0;
	}
	
	$run_status->{state_xls} = 1;
	$run_status->{state_xls_info} = 'xlsx file created';
	$run_status->{last_xls_dtg} = $dtg;
	$run_status->{xls_files}->{count} = 1;

	return $task_id;
}

sub write_nested_code_tables {
	my ($cat,$taskid,$option,$worksheet,$href,$heading_format1,$heading_format2,$center_format,$trace) = @_;
	my $me = "WRITE-NESTEDCODE-TABLES";
	$me = $me . "][Option:$option][taskid:$taskid][cat:$cat";
	my $update_data_coding = 0;
	
	my $headspace = 4;
	my $row_headspace = 3;
	
	my $big_cutoff = 10;
	my $big_off_trigger = 200;
	my $primary_limit = 16;
	my $all_codes_nested = '---';
	
	my $code_title_col = 1;
	my $code_l2_title_col = 2;
	my $code_l3_title_col = 3;
	my $code_nested_title_col = 2;
	my $code_col_width = 12;
	my $code_l2_col_width = 15;
	my $code_l3_col_width = 70;
	my $code_nested_col_width = 65;
	my $blank_col_width = 3;
	my $code_rank_col = 0;
	my $code_rank_col_width = 7;
	my $code_words_col = 4;
	my $code_words_col_width = 8;
	my $code_tbase_lines_col = 6;
	my $code_tbase_words_col = 7;
	my $code_nested_lines_col = 8;
	my $code_nested_words_col = 9;
	my $code_total_lines_col = 10;
	my $code_total_words_col = 11;
	my $code_ctr_codes_col = 12;
	my $code_code_ctr_col = 15;
	my $code_percent1_words_col = 14;
	my $code_percent2_words_col = 15;
	my $code_iname_ct_col = 18;
	my $code_iname_ct_col_width = 6;
	my $code_dis_ratio_col = 19;
	my $code_dis_ratio_col_width = 8;
	my $code_wd_mean_col = 5;
	my $code_wd_mean_col_width = 8;
	
	my $blank_col = $code_title_col + 19;
	my $start_jump_col = 18;

	my %place_ctr = ();
	my $ct = 1;
#	foreach my $iname (keys %{ $run_status->{active_xls_iname_percodestats} }) {
#		$place_ctr{$iname} = $ct;
#		$ct++;
#	}
	foreach my $iname_index (keys %{ $run_status->{active_xls_iname_rank_order} }) {
		my $iname = $run_status->{active_xls_iname_rank_order}->{$iname_index};
		$place_ctr{$iname} = $iname_index;
	}
	$ct = scalar(keys %place_ctr);
	say "[$me] active iname ct[".scalar(keys %place_ctr)."]" if $trace;
	
	## make header rows
	my $row_start = $headspace;
	my $col_inc = $code_title_col;
	$worksheet->write($row_start+2, $col_inc, "Main Code", $heading_format1);
#	$worksheet->write($row_start+2, $col_inc+1, "Level 2 SubCode", $heading_format1);
#	$worksheet->write($row_start+2, $col_inc+2, "Level 3+ SubCode", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc-1), "Ranking", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+3), "Words", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+3), "Counts", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+4), "Words", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+4), "Means", $heading_format1);
	## spkr counts cols
	$worksheet->write($row_start, ($col_inc+17), "Base", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+17), "SPKR", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+17), "Count", $heading_format1);
	$worksheet->write($row_start, ($col_inc+18), "Subtree", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+18), "SPKR", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+18), "Count", $heading_format1);
	## nested cols
	$worksheet->write($row_start+2, ($col_inc+7), "Counts", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+7), "Added", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+8), "Words", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+8), "Added", $heading_format1);
	## tbase cols
	$worksheet->write($row_start+2, ($col_inc+5), "Counts", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+5), "TBase", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+6), "Words", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+6), "TBase", $heading_format1);
	## total cols
	$worksheet->write($row_start+2, ($col_inc+9), "Counts", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+9), "Total", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+10), "Words", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+10), "Total", $heading_format1);

	my $start_main_sum_row = $row_start + $row_headspace;
	my $end_main_sum_row = 145;
	my $col_add = 1;
	$col_inc = $col_inc + $col_add + $start_jump_col;
	$worksheet->write($row_start-1, ($col_inc+1), "Base", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Freq", $heading_format1);
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Words", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	## adjust for $col_add starting at 1 and not 0
	$col_inc--;
	$worksheet->write($row_start-1, ($col_inc+1), "Base", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Freqs", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Count", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start-1, ($col_inc+1), "Subtree", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Freq", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Words", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start-1, ($col_inc+1), "Subtree", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Freq", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Count", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start-1, ($col_inc+1), "Total", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Freq", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Words", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start-1, ($col_inc+1), "Total", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Freq", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Count", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$col_inc++;
	
	my $spacing = scalar(keys %place_ctr);

	if($option) {
		## make sheet title
		$worksheet->write(0, 0, "Nested Codes - Summary Stats by Speaker - 1 unit == 1 sentence", $heading_format2);
	} else {
		## make sheet title
		$worksheet->write(0, 0, "Nested Codes - Summary Stats by Speaker - 1 unit == 1 sentence", $heading_format2);
	}
	
	$worksheet->set_column($code_rank_col, $code_rank_col, $code_rank_col_width);
	$worksheet->set_column($code_words_col, $code_words_col, $code_words_col_width);
	$worksheet->set_column($code_title_col, $code_title_col, $code_col_width);
	$worksheet->set_column($code_l2_title_col, $code_l2_title_col, $code_l2_col_width);
	$worksheet->set_column($code_l3_title_col, $code_l3_title_col, $code_l3_col_width);
	$worksheet->set_column($code_iname_ct_col, $code_iname_ct_col, $code_iname_ct_col_width);
	$worksheet->set_column($code_wd_mean_col, $code_wd_mean_col, $code_wd_mean_col_width);
	$worksheet->set_column($code_tbase_lines_col, $code_tbase_lines_col, $code_iname_ct_col_width);
	$worksheet->set_column($blank_col, $blank_col, $blank_col_width);

	if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes} })) {
		say "[$me] nested codehref error...nested code list is not valid!";
		die "\tdying to fix at[".__LINE__."]\n";
	}
	my $nested_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes};
	say "[$me] nested codes loaded...size[".scalar(keys %$nested_codehref)."]" if $trace;
		
	if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_base_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_base_codes} })) {
		say "[$me] base codehref error...base code list is not valid!";
		die "\tdying to fix at[".__LINE__."]\n";
	}
	my $base_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_base_codes};
	say "[$me] base codes loaded...size[".scalar(keys %$base_codehref)."]" if $trace;

	my $start_col = $blank_col; ## increment cols after the blank col value
	my $padding = 1;
	my $rows = 0;
	my $row_ctr = $row_start + $row_headspace;
	if(scalar(keys %$base_codehref)) {
		my $low_limit = 1;
		if(exists $post_text_config->{prime_code_count_low_limit} and $post_text_config->{prime_code_count_low_limit}) {
			$low_limit = $post_text_config->{prime_code_count_low_limit};
		}
		my $_sorter = {};
		my $p_sorter = {};
		my $big_word_total = 0;
		foreach my $code (keys %$base_codehref) {
			my $total = 0;
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count}) {
				$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count};
			}
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count}) {
				$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count};
			}
			$p_sorter->{$code} = $total;
			$big_word_total = $big_word_total + $total;
		}
		foreach my $code (keys %$nested_codehref) {
			my $total = 0;
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count}) {
				$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count};
			}
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count}) {
				$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count};
			}
			$_sorter->{$code} = $total;
		}
		if($option) {
			my $code_ctr = 1;
			my $c_ctr = 0;
			foreach my $code (sort { $p_sorter->{$b} <=> $p_sorter->{$a} } keys %$p_sorter) {
				if($code_ctr > $primary_limit) {
					say " [$me] that's all folks, [$primary_limit] codes have been written, X_code_stats, rejecting code[$code]";
					last;
				}
				my $allcount = $_sorter->{$code};
				if($low_limit > $allcount) {
					say " [$me] nested code summary, X_code_stats, code[$code] code size too small[".$allcount."]";
					next;
				}
				my $text_code = $data_coding->{runlinks}->{code_form_mapping}->{$code};
				if(!$text_code) { $text_code = $code; } ## if no match text_code, use code value
				$worksheet->write($row_ctr, $code_title_col, $text_code);
				my $allwords = 0;
				my $nestedlines = 0;
				my $nestedwords = 0;
				my $tlines = 0;
				my $twords = 0;
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}) {
					$allwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}) {
					$allwords = $allwords + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}->{count};
				}
					
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}) {
					$nestedlines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}) {
					$nestedwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}) {
					$tlines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}) {
					$twords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}->{count};
				}
				## write ranking cols (0 & 1)
				$worksheet->write($row_ctr, $code_rank_col, $allcount, $center_format);
				$worksheet->write($row_ctr, $code_words_col, $allwords, $center_format);
				## write total codes values
				$worksheet->write($row_ctr, $code_nested_lines_col, $allcount, $center_format);
				$worksheet->write($row_ctr, $code_nested_words_col, $allwords, $center_format);
				$worksheet->write($row_ctr, $code_total_lines_col, $tlines, $center_format);
				$worksheet->write($row_ctr, $code_total_words_col, $twords, $center_format);

				if($p_sorter->{$code} < $big_off_trigger) {
					$big_cutoff = 0;
				}

				my $print_code = undef;
				my $_L2_sorter = {};
				my $_L2_mapper = {};
				foreach my $_code (sort { $_sorter->{$b} <=> $_sorter->{$a} } keys %$_sorter) {
					if($_sorter->{$_code} < $big_cutoff) {
						next;
					}
					my $base_code = $data_coding->{runlinks}->{code_tree_base}->{$_code};
					if(!$base_code) {
						if($_code!~/___/) {
							next;
						}
						my @pts = split "___",$_code;
						if(!scalar(@pts)) {
							die "\t[$me]...what the hell....splitting[$_code] broke at line[".__LINE__."]\n";
						}
						$base_code = $pts[0];
						say "[$me] NEW base_code[$base_code] for _code[$_code]";
						$data_coding->{runlinks}->{code_tree_base}->{$_code} = $base_code;
						$update_data_coding = 1;
					}
					if($_code eq $base_code) {
						## nested code matches base code...already done...skip
						next;
					}
					
					if($code eq $base_code) {
						my $re_code = $_code;
						$re_code =~ s/___/::/g;
						my $clayers = &make_code_layers($re_code,undef,$taskid,$trace);
						if(scalar(keys %$clayers) > 1) {
							if(exists $clayers->{2} and exists $clayers->{2}) {
								if(!exists $_L2_mapper->{ $clayers->{2} }) {
									$_L2_mapper->{ $clayers->{2} } = [];
								}
								my $pusher = $_L2_mapper->{ $clayers->{2} };
								push @$pusher,$_code;
								if(!exists $_L2_sorter->{ $clayers->{2} }) {
									$_L2_sorter->{ $clayers->{2} } = 0;
								}

								if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{ $clayers->{2} }->{lines}->{tbase}) {
									$_L2_sorter->{ $clayers->{2} } = $_L2_sorter->{ $clayers->{2} } + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{ $clayers->{2} }->{lines}->{tbase}->{count};
								}
								if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{ $clayers->{2} }->{lines}->{subtree}) {
									$_L2_sorter->{ $clayers->{2} } = $_L2_sorter->{ $clayers->{2} } + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{ $clayers->{2} }->{lines}->{subtree}->{count};
								}
							}
						}
					}
				}
				my $_row_sorter = {};
				my $_row_values = {};
				my $_row_total_mapper = {};
				my $_row_totals = {};
				my $skip = 1;
				foreach my $_code2 (sort { $_L2_sorter->{$b} <=> $_L2_sorter->{$a} } keys %$_L2_sorter) {
					my $head = 1;
					my $go_codes = 1;
					my $linger_code = undef;
					while($go_codes) {
						my $print_code = undef;
						my $prt_code = undef;
						if($head) {
							if($skip) {
								$print_code = $code;
								$skip = 0;
							} else {
								$print_code = $_code2;
								if(exists $_L2_mapper->{ $_code2 }) {
									$prt_code = shift @{ $_L2_mapper->{ $_code2 }};
								}
								$head--;
							}
						} else {
							if(exists $_L2_mapper->{ $_code2 }) {
								if(scalar(@{ $_L2_mapper->{ $_code2 } })) {
									$print_code = shift @{ $_L2_mapper->{ $_code2 }};
								}
							}
						}
						if(!$print_code) {
							$go_codes = 0;
							last;
						}
						my $t_code = $data_coding->{runlinks}->{code_form_mapping}->{$print_code};
						if(!$t_code) {
							$t_code = $print_code;
							$t_code =~ s/___/::/g;
							say "[$me] BAD code mapping[$code][$_code2][$print_code] to t_code[$t_code]";
						}
						my $prt_l2_code = "_NA_";
						my $prt_l3_code = undef;
						if($t_code=~/::/) {
							my @pts = split "::",$t_code;
							if(scalar(@pts)>1) {
								$prt_l2_code = $pts[1];
							}
							if(scalar(@pts)>2) {
								$prt_l3_code = $pts[2];
							}
							for(my $p=2; $p<(scalar(@pts)); $p++) {
								$prt_l2_code = $prt_l2_code . "::" . $pts[$p];
								if($p>2) {
									$prt_l3_code = $prt_l3_code . "::" . $pts[$p];
								}
							}
						}
						if($prt_code) {
							$worksheet->write($row_ctr, $code_l2_title_col, $prt_l2_code);
							$linger_code = $prt_l2_code;
						} else {
							if($prt_l3_code) {
								$worksheet->write($row_ctr, $code_l3_title_col, $prt_l3_code);
								$worksheet->write($row_ctr, $code_l2_title_col, $linger_code);
							} else {
								## blank top row...
								$_row_total_mapper->{$code} = $row_ctr;
							}
						}
						if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}) {
							my $_allwords = 0;
							my $_tbaselines = 0;
							my $_ictr_tbaselines = 0;
							my $_tbasewords = 0;
							my $_nestedlines = 0;
							my $_ictr_subtreelines = 0;
							my $_nestedwords = 0;
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{tbase}) {
								$_tbaselines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{count};
								if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{inames}) {
									$_ictr_tbaselines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{inames};
								}
							}
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{words}->{tbase}) {
								$_tbasewords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{words}->{tbase}->{count};
								$_allwords = $_tbasewords;
								$c_ctr++;
							}
							$_row_sorter->{$row_ctr} = $_tbasewords;
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{subtree}) {
								$_nestedlines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{count};
								if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{inames}) {
									$_ictr_subtreelines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{inames};
								}
							}
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{words}->{subtree}) {
								$_nestedwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{words}->{subtree}->{count};
							}
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$print_code}->{words}->{subtree}) {
								$_allwords = $_allwords + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$print_code}->{words}->{subtree}->{count};
							}
							if(!exists $_row_totals->{$code}) {
								$_row_totals->{$code} = 0;
							}
							$_row_totals->{$code} = $_tbaselines;
							
							my $_totallines = $_tbaselines + $_nestedlines;
							my $_totalwords = $_tbasewords + $_nestedwords;
							$worksheet->write($row_ctr, $code_words_col, $_allwords, $center_format);
							$worksheet->write($row_ctr, $code_tbase_lines_col, $_tbaselines, $center_format);
							$worksheet->write($row_ctr, $code_tbase_words_col, $_tbasewords, $center_format);
							$worksheet->write($row_ctr, $code_total_lines_col, $_totallines, $center_format);
							$worksheet->write($row_ctr, $code_total_words_col, $_totalwords, $center_format);
							$worksheet->write($row_ctr, $code_nested_lines_col, $_nestedlines, $center_format);
							$worksheet->write($row_ctr, $code_nested_words_col, $_nestedwords, $center_format);
							$worksheet->write($row_ctr, $code_iname_ct_col, $_ictr_tbaselines, $center_format);
#							$worksheet->write($row_ctr, $code_dis_ratio_col, $_ictr_subtreelines, $center_format);

							if($_totallines) {
							
								my $allinames = 0;
								my $allratio = 0;
								my $word_sum = 0;

								foreach my $iname (keys %place_ctr) {
									my $ct = $place_ctr{$iname};
#									my $count_col = $start_col + $ct;
									my $base_words_col = $start_col + $ct;
									my $base_count_col = $start_col + $spacing + $ct;
									my $subtree_words_col = $start_col + $spacing + $spacing + $ct;
									my $subtree_count_col = $start_col + $spacing + $spacing + $spacing + $ct;
									my $words_col = $start_col + $spacing + $spacing + $spacing + $spacing + $ct;
									my $count_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
									my $inten_col = $start_col + $spacing + $spacing + $spacing + $spacing + $ct;
									my $narrow_ratio_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing + $ct;
#									my $narrow_ratio_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
									my $disp_col = $start_col + $padding + $spacing + $spacing + $spacing  + $spacing + $spacing + $spacing + $spacing + $ct;
									my $tmean_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing  + $spacing + $spacing + $spacing + $spacing + $ct;
				
									my $tbase_count = 0;
									my $tbase_words = 0;
									my $subtree_count = 0;
									my $subtree_words = 0;
									my $tcount = 0;
									my $chars = 0;
									my $words = 0;
									my $intensity = 0;
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{tbase} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{count}) {
										$tcount = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{count};
										$tbase_count = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{count};
									}
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{subtree} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{count}) {
										$tcount = $tcount + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{count};
										$subtree_count = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{count};
									}
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{tbase} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{tbase}->{count}) {
										$words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{tbase}->{count};
										$tbase_words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{tbase}->{count};
										$word_sum = $word_sum + $words;
									}
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{subtree} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{subtree}->{count}) {
										$words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{subtree}->{count};
										$subtree_words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{subtree}->{count};
										$word_sum = $word_sum + $words;
									}
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{chars}->{tbase} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{chars}->{tbase}->{count}) {
										$chars = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{chars}->{tbase}->{count};
									}
									if($tcount) {
										$worksheet->write($row_ctr, $count_col, $tcount);
									}
									if($tbase_count) {
										$worksheet->write($row_ctr, $base_count_col, $tbase_count);
									}
									if($subtree_count) {
										$worksheet->write($row_ctr, $subtree_count_col, $subtree_count);
									}
									if($words) {
										$worksheet->write($row_ctr, $words_col, $words, $center_format);
										$allinames++;
									}
									if($tbase_words) {
										$worksheet->write($row_ctr, $base_words_col, $tbase_words);
									}
									if($subtree_words) {
										$worksheet->write($row_ctr, $subtree_words_col, $subtree_words);
									}
									if($chars) {
#										$worksheet->write($row_ctr, $chars_col, $chars, $center_format);
									}

									if($tcount) {
										$intensity = $words / $tcount;
									}
									## give 2 digits to the right
									if($intensity=~/([\d]+)(\.[\d]+)/) {
										my $digits = $2 * 100;
										my $first = $1;
										my $second = '00';
										if($digits=~/([\d]+)\.([\d]*)/) {
											$second = $1;
											if($second < 10) {
												$second = "0" . $second;
											}
										}
										$intensity = $first . "." . $second;
									}
#									if($intensity) {
#										$worksheet->write($row_ctr, $inten_col, $intensity);
#									}
								}
								my $cts = scalar(keys %place_ctr);
								my $iname_avg = 0;
								if($cts) {
									my $avg = $word_sum / $cts;
									$iname_avg = 0;
									if($allinames) {
										$iname_avg = $word_sum / $allinames;
									}
									if($avg) {
										$allratio = $iname_avg / $avg;
									}
									## give 2 digits to the right
									if($allratio=~/([\d]+)(\.[\d]+)/) {
										my $digits = $2 * 100;
										my $first = $1;
										my $second = '00';
										if($digits=~/([\d]+)([\.\d]*)/) {
											$second = $1;
											if($second < 10) {
												$second = "0" . $second;
											}
										}
										$allratio = $first . "." . $second;
									}
									## give 2 digits to the right
									if($iname_avg=~/([\d]+)(\.[\d]+)/) {
										my $digits = $2 * 100;
										my $first = $1;
										my $second = '00';
										if($digits=~/([\d]+)([\.\d]*)/) {
											$second = $1;
											if($second < 10) {
												$second = "0" . $second;
											}
										}
										$iname_avg = $first . "." . $second;
									} else {
										$iname_avg = $iname_avg . ".00";
									}
								}
#								$worksheet->write($row_ctr, $code_wd_mean_col, $iname_avg, $center_format);
								$worksheet->write($row_ctr, $code_iname_ct_col, $allinames, $center_format);

							}
							
						}
						$worksheet->write($row_ctr, $code_code_ctr_col, $c_ctr, $center_format);
						$row_ctr++;
					}
				}
				my $cktr = 1;
				my $w_total = 0;
				$worksheet->write($_row_total_mapper->{$code}, $code_ctr_codes_col, $_row_totals->{$code}, $center_format);
				foreach my $_row (sort { $_row_sorter->{$b} <=> $_row_sorter->{$a} } keys %$_row_sorter) {
					my $words = $_row_sorter->{$_row};
#					$w_total = $w_total + $words;
#					my $ratio = $w_total / $_row_totals->{$code};
					$worksheet->write($_row, $code_ctr_codes_col, $words, $center_format);
					$worksheet->write($_row, $code_ctr_codes_col+1, $cktr, $center_format);
#					$worksheet->write($_row, $code_ctr_codes_col+2, $w_total, $center_format);
#					$worksheet->write($_row, $code_ctr_codes_col+3, $ratio, $center_format);
#					$worksheet->write($_row, $code_ctr_codes_col+4, $_row_totals->{$code}, $center_format);
					$cktr++;
				}
#				$_row_total_mapper->{$code} = $row_ctr;
#				$_row_totals->{$code} = $_row_totals->{$code} + $_tbaselines;
				
				$code_ctr++;
			}
		} else {
			foreach my $code (sort { $p_sorter->{$b} <=> $p_sorter->{$a} } keys %$p_sorter) {
				my $allcount = $_sorter->{$code};
				if($low_limit > $allcount) {
					say " [$me] nested code summary, X_code_stats, code[$code] code size too small[".$allcount."]";
					next;
				}
				my $text_code = $data_coding->{runlinks}->{code_form_mapping}->{$code};
				if(!$text_code) { $text_code = $code; } ## if no match text_code, use code value
				$worksheet->write($row_ctr, $code_title_col, $text_code);
				my $allwords = 0;
				my $nestedlines = 0;
				my $nestedwords = 0;
				my $tlines = 0;
				my $twords = 0;
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}) {
					$allwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}) {
					$allwords = $allwords + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}->{count};
				}
					
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}) {
					$nestedlines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}) {
					$nestedwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}) {
					$tlines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}) {
					$twords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}->{count};
				}
				## write ranking cols (0 & 1)
				$worksheet->write($row_ctr, $code_rank_col, $allcount, $center_format);
				$worksheet->write($row_ctr, $code_words_col, $allwords, $center_format);
				## write total codes values
				$worksheet->write($row_ctr, $code_nested_lines_col, $allcount, $center_format);
				$worksheet->write($row_ctr, $code_nested_words_col, $allwords, $center_format);
				$worksheet->write($row_ctr, $code_total_lines_col, $tlines, $center_format);
				$worksheet->write($row_ctr, $code_total_words_col, $twords, $center_format);

				if($p_sorter->{$code} < $big_off_trigger) {
					$big_cutoff = 0;
				}
				


				my $ktr = 0;
				my $print_code = undef;
				my $_L2_sorter = {};
				my $_L2_mapper = {};
				foreach my $_code (sort { $_sorter->{$b} <=> $_sorter->{$a} } keys %$_sorter) {
					if($_sorter->{$_code} < $big_cutoff) {
						next;
					}
					my $base_code = $data_coding->{runlinks}->{code_tree_base}->{$_code};
					if(!$base_code) {
						if($_code!~/___/) {
							next;
						}
						my @pts = split "___",$_code;
						if(!scalar(@pts)) {
							die "\t[$me]...what the hell....splitting[$_code] broke at line[".__LINE__."]\n";
						}
						$base_code = $pts[0];
						say "[$me] NEW base_code[$base_code] for _code[$_code]";
						$data_coding->{runlinks}->{code_tree_base}->{$_code} = $base_code;
						$update_data_coding = 1;
					}
					if($_code eq $base_code) {
						## nested code matches base code...already done...skip
						next;
					}
					
					if($code eq $base_code) {
						my $re_code = $_code;
						$re_code =~ s/___/::/g;
						my $clayers = &make_code_layers($re_code,undef,$taskid,$trace);
						if(scalar(keys %$clayers) > 1) {
							if(exists $clayers->{2} and exists $clayers->{2}) {
	#							my $_code2 = $clayers->{2};
								if(!exists $_L2_mapper->{ $clayers->{2} }) {
									$_L2_mapper->{ $clayers->{2} } = [];
								}
								my $pusher = $_L2_mapper->{ $clayers->{2} };
								push @$pusher,$_code;
								if(!exists $_L2_sorter->{ $clayers->{2} }) {
									$_L2_sorter->{ $clayers->{2} } = 0;
								}

	#							$_L2_mapper->{ $clayers->{2} } = $_code;
								if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{ $clayers->{2} }->{lines}->{tbase}) {
									$_L2_sorter->{ $clayers->{2} } = $_L2_sorter->{ $clayers->{2} } + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{ $clayers->{2} }->{lines}->{tbase}->{count};
								}
								if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{ $clayers->{2} }->{lines}->{subtree}) {
									$_L2_sorter->{ $clayers->{2} } = $_L2_sorter->{ $clayers->{2} } + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{ $clayers->{2} }->{lines}->{subtree}->{count};
								}
							}
						}
					}
				}
				my $_row_sorter = {};
				my $skip = 1;
				foreach my $_code2 (sort { $_L2_sorter->{$b} <=> $_L2_sorter->{$a} } keys %$_L2_sorter) {
					my $head = 1;
					my $go_codes = 1;
					while($go_codes) {
						my $print_code = undef;
						my $prt_code = undef;
						if($head) {
							if($skip) {
								$print_code = $code;
								$skip = 0;
							} else {
								$print_code = $_code2;
								if(exists $_L2_mapper->{ $_code2 }) {
									$prt_code = shift @{ $_L2_mapper->{ $_code2 }};
								}
								$head--;
							}
						} else {
							if(exists $_L2_mapper->{ $_code2 }) {
								if(scalar(@{ $_L2_mapper->{ $_code2 } })) {
									$print_code = shift @{ $_L2_mapper->{ $_code2 }};
	#								if(!$print_code or $print_code=~/^\s+$/) {
	#									die;
	#								}
								}
							}
						}
						if(!$print_code) {
							$go_codes = 0;
							last;
						}
	#					if(!defined $print_code and !defined $prt_code) {
	#						$go_codes = 0;
	#						last;
	#					}
						my $t_code = $data_coding->{runlinks}->{code_form_mapping}->{$print_code};
						if(!$t_code) {
							$t_code = $print_code;
							$t_code =~ s/___/::/g;
							say "[$me] BAD code mapping[$code][$_code2][$print_code] to t_code[$t_code]";
	#						$data_coding->{runlinks}->{code_form_mapping}->{$_code} = $t_code;
		#						$update_data_coding = 1;
						}
						my $prt_l2_code = "_NA_";
						my $prt_l3_code = undef;
						if($t_code=~/::/) {
							my @pts = split "::",$t_code;
							if(scalar(@pts)>1) {
								$prt_l2_code = $pts[1];
							}
							if(scalar(@pts)>2) {
								$prt_l3_code = $pts[2];
							}
							for(my $p=2; $p<(scalar(@pts)); $p++) {
								$prt_l2_code = $prt_l2_code . "::" . $pts[$p];
								if($p>2) {
									$prt_l3_code = $prt_l3_code . "::" . $pts[$p];
								}
							}
						}
						if($prt_code) {
							$worksheet->write($row_ctr, $code_l2_title_col, $prt_l2_code);
						} else {
	#						$prt_l3_code = "XX - " . $prt_l3_code;
	#						if(!defined $prt_l3_code) {
	#							$go_codes = 0;
	#							next;
	#						}
							$worksheet->write($row_ctr, $code_l3_title_col, $prt_l3_code);
						}
						if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}) {
							my $_allwords = 0;
							my $_tbaselines = 0;
							my $_ictr_tbaselines = 0;
							my $_tbasewords = 0;
							my $_nestedlines = 0;
							my $_ictr_subtreelines = 0;
							my $_nestedwords = 0;
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{tbase}) {
								$_tbaselines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{count};
								if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{inames}) {
									$_ictr_tbaselines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{inames};
								}
							}
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{words}->{tbase}) {
								$_tbasewords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{words}->{tbase}->{count};
								$_allwords = $_tbasewords;
							}
							$_row_sorter->{$row_ctr} = $_tbasewords;
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{subtree}) {
								$_nestedlines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{count};
								if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{inames}) {
									$_ictr_subtreelines = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{inames};
								}
							}
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{words}->{subtree}) {
								$_nestedwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$print_code}->{words}->{subtree}->{count};
							}
							if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$print_code}->{words}->{subtree}) {
								$_allwords = $_allwords + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$print_code}->{words}->{subtree}->{count};
							}

							my $_totallines = $_tbaselines + $_nestedlines;
							my $_totalwords = $_tbasewords + $_nestedwords;
							$worksheet->write($row_ctr, $code_words_col, $_allwords, $center_format);
							$worksheet->write($row_ctr, $code_tbase_lines_col, $_tbaselines, $center_format);
							$worksheet->write($row_ctr, $code_tbase_words_col, $_tbasewords, $center_format);
							$worksheet->write($row_ctr, $code_total_lines_col, $_totallines, $center_format);
							$worksheet->write($row_ctr, $code_total_words_col, $_totalwords, $center_format);
							$worksheet->write($row_ctr, $code_nested_lines_col, $_nestedlines, $center_format);
							$worksheet->write($row_ctr, $code_nested_words_col, $_nestedwords, $center_format);
							$worksheet->write($row_ctr, $code_iname_ct_col, $_ictr_tbaselines, $center_format);
							$worksheet->write($row_ctr, $code_dis_ratio_col, $_ictr_subtreelines, $center_format);

							if($_totallines) {
							
								my $allinames = 0;
								my $allratio = 0;
								my $word_sum = 0;

								foreach my $iname (keys %place_ctr) {
									my $ct = $place_ctr{$iname};
									my $base_words_col = $start_col + $ct;
									my $words_col = $start_col + $spacing + $ct;
									my $base_count_col = $start_col + $spacing + $spacing + $ct;
									my $count_col = $start_col + $spacing + $spacing + $spacing + $ct;
#									my $count_col = $start_col + $ct;
#									my $words_col = $start_col + $spacing + $ct;
#									my $chars_col = $start_col + $spacing + $spacing + $ct;
#									my $inten_col = $start_col + $spacing + $spacing + $spacing + $ct;
									my $narrow_ratio_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing + $ct;
									my $disp_col = $start_col + $padding + $spacing + $spacing + $spacing  + $spacing + $spacing + $ct;
									my $tmean_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing  + $spacing + $spacing + $ct;
									
									my $tbase_count = 0;
									my $tbase_words = 0;
									my $subtree_count = 0;
									my $subtree_words = 0;
									my $tcount = 0;
									my $chars = 0;
									my $words = 0;
									my $intensity = 0;
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{tbase} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{count}) {
										$tcount = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{count};
										$tbase_count = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{tbase}->{count};
									}
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{subtree} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{count}) {
										$tcount = $tcount + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{lines}->{subtree}->{count};
									}
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{tbase} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{tbase}->{count}) {
										$words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{tbase}->{count};
										$tbase_words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{tbase}->{count};
										$word_sum = $word_sum + $words;
									}
									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{subtree} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{subtree}->{count}) {
										$words = $words + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{subtree}->{count};
										$subtree_words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{words}->{subtree}->{count};
										$word_sum = $word_sum + $words;
									}
#									if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{chars}->{tbase} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{chars}->{tbase}->{count}) {
#										$chars = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$print_code}->{chars}->{tbase}->{count};
#									}
									if($tcount) {
										$worksheet->write($row_ctr, $count_col, $tcount);
									}
									if($words) {
										$worksheet->write($row_ctr, $words_col, $words, $center_format);
										$allinames++;
									}
									if($tbase_count) {
										$worksheet->write($row_ctr, $base_count_col, $tbase_count);
									}
									if($tbase_words) {
										$worksheet->write($row_ctr, $base_words_col, $tbase_words);
									}
#									if($chars) {
#										$worksheet->write($row_ctr, $chars_col, $chars, $center_format);
#									}

									if($tcount) {
										$intensity = $chars / $tcount;
									}
									## give 2 digits to the right
									if($intensity=~/([\d]+)(\.[\d]+)/) {
										my $digits = $2 * 100;
										my $first = $1;
										my $second = '00';
										if($digits=~/([\d]+)\.([\d]*)/) {
											$second = $1;
											if($second < 10) {
												$second = "0" . $second;
											}
										}
										$intensity = $first . "." . $second;
									}
#									if($intensity) {
#										$worksheet->write($row_ctr, $inten_col, $intensity);
#									}
								}
								my $cts = scalar(keys %place_ctr);
								my $iname_avg = 0;
								if($cts) {
									my $avg = $word_sum / $cts;
									$iname_avg = 0;
									if($allinames) {
										$iname_avg = $word_sum / $allinames;
									}
									if($avg) {
										$allratio = $iname_avg / $avg;
									}
									## give 2 digits to the right
									if($allratio=~/([\d]+)(\.[\d]+)/) {
										my $digits = $2 * 100;
										my $first = $1;
										my $second = '00';
										if($digits=~/([\d]+)([\.\d]*)/) {
											$second = $1;
											if($second < 10) {
												$second = "0" . $second;
											}
										}
										$allratio = $first . "." . $second;
									}
									## give 2 digits to the right
									if($iname_avg=~/([\d]+)(\.[\d]+)/) {
										my $digits = $2 * 100;
										my $first = $1;
										my $second = '00';
										if($digits=~/([\d]+)([\.\d]*)/) {
											$second = $1;
											if($second < 10) {
												$second = "0" . $second;
											}
										}
										$iname_avg = $first . "." . $second;
									} else {
										$iname_avg = $iname_avg . ".00";
									}
								}
								$worksheet->write($row_ctr, $code_wd_mean_col, $iname_avg, $center_format);

							}
							
						}
						$row_ctr++;
					}
				}
				my $cktr = 1;
				foreach my $_row (sort { $_row_sorter->{$b} <=> $_row_sorter->{$a} } keys %$_row_sorter) {
					my $words = $_row_sorter->{$_row};
					$worksheet->write($_row, $code_ctr_codes_col, $words, $center_format);
					$worksheet->write($_row, $code_ctr_codes_col+1, $cktr, $center_format);
					$cktr++;
				}
			}
		}
	}
	
	if($update_data_coding) {
		$codes_dirty->{re_codes} = 1;
	}

	return $taskid;
}
sub write_per_code_tables {
	my ($cat,$taskid,$option,$worksheet,$href,$heading_format1,$heading_format2,$center_format,$trace) = @_;
	my $me = "WRITE-PERCODE-TABLES";
	$me = $me . "][Option:$option][taskid:$taskid][cat:$cat";
	
	my $headspace = 4;
	my $row_headspace = 3;
	
	my $blank_col_width = 3;
	my $code_rank_col = 0;
	my $code_rank_col_width = 7;
	my $code_words_col = 2;
	my $code_words_col_width = 8;
	my $code_title_col = 1;
	my $code_col_width = 60;
	my $code_iname_ct_col = 6;
	my $code_iname_ct_col_width = 6;
	my $code_dis_ratio_col = 6;
	my $code_dis_ratio_col_width = 8;
	my $code_wd_mean_col = 3;
	my $code_wd_mean_col_width = 8;
	my $code_percent1_col = 4;
	my $code_percent1_col_width = 10;
	my $code_percent2_col = 5;
	my $code_percent2_col_width = 8;
	my $code_cumm_percent_col = 5;
	my $code_code_ctr_col = 7;
	
	my $words_sum_start_offset = 31;
	
	my $blank_col = $code_title_col + 7;
	my $start_jump_col = 6;

	if(!defined $data_post_coding) {
		die "[$me] data_stat_linkage data variable is not loaded...check file load! at line[".__LINE__."]\n";
	}
	if(!exists $data_post_coding->{post_coding}) {
		die "[$me] data_post_coding {post_coding} hash has a bad structure at line[".__LINE__."]\n";
	}
	my $statlinks = $data_stats_linkage->{by_iname};

	my %place_ctr = ();
	my $ct = 1;
	foreach my $iname (keys %$href) {
		$place_ctr{$iname} = $ct;
		$run_status->{active_xls_iname_percodestats}->{$iname} = 'prev-' . $place_ctr{$iname};
		$ct++;
	}
	foreach my $iname (keys %$statlinks) {
		if(!exists $place_ctr{$iname}) {
			$place_ctr{$iname} = $ct;
			$ct++;
		}
		$run_status->{active_xls_iname_percodestats}->{$iname} = $place_ctr{$iname};
	}
	foreach my $iname_index (keys %{ $run_status->{active_xls_iname_rank_order} }) {
		my $iname = $run_status->{active_xls_iname_rank_order}->{$iname_index};
		$place_ctr{$iname} = $iname_index;
	}
	$ct = scalar(keys %place_ctr);

	say "[$me] active iname ct[".scalar(keys %place_ctr)."]";
	
	## make header rows
	my $row_start = $headspace;
	my $col_inc = $code_title_col;
	$worksheet->write($row_start+2, $col_inc, "Code Name", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+4), "SPKR", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+4), "Count", $heading_format1);
	$worksheet->write($row_start, ($col_inc+5), "Base", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+5), "SPKR", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+5), "Counts", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc-1), "Ranking", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+1), "Word", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+1), "Counts", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+2), "Word", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+2), "Means", $heading_format1);
	$worksheet->write($row_start, ($col_inc+3), "Word", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+3), "Percent", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+3), "Contribute", $heading_format1);
	$worksheet->write($row_start, ($col_inc+3), "Word", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+4), "Percent", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+5), "Cumm", $heading_format1);

	my $col_add = 1;
	my $start_main_sum_row = $row_start + $row_headspace;
	my $end_main_sum_row = 145;
	$col_inc = $col_inc + $col_add + $start_jump_col;
	$worksheet->write($row_start-1, ($col_inc+1), "Base + Tree", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Freq", $heading_format1);
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Words", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-2, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	## adjust for $col_add starting at 1 and not 0
	$col_inc--;
	$worksheet->write($row_start-1, ($col_inc+1), "Base + Tree", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Freqs", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Count", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-2, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start-1, ($col_inc+1), "Base + Tree", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Weight", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Chars", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
#		my $ckey = $ct+$col_inc;
#		my $col_alpha = $col_converter{$ckey};
#		my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
#		$worksheet->write_formula( $row_start-1, $ckey, $sumform, $center_format );
#		$worksheet->write($row_start-2, $ckey, "Sum", $heading_format1);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start-1, ($col_inc+1), "Intensity", $heading_format2);
	$worksheet->write($row_start, ($col_inc+1), "Words/Count", $heading_format2);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Wds/Ct", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		my $ckey = $ct+$col_inc;
		my $col_alpha = $col_converter{$ckey};
		my $sumform = "=AVERAGE(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
		$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
		$worksheet->write($row_start-3, $ckey, "Avg", $heading_format1);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start, ($col_inc+1), "Base", $heading_format2);
	$worksheet->write($row_start+1, ($col_inc+1), "Freq", $heading_format2);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Words", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		my $ckey = $ct+$col_inc;
		my $col_alpha = $col_converter{$ckey};
		my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
		$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
		$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start, ($col_inc+1), "Base", $heading_format2);
	$worksheet->write($row_start+1, ($col_inc+1), "Freq", $heading_format2);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Counts", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		my $ckey = $ct+$col_inc;
		my $col_alpha = $col_converter{$ckey};
		my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
		$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
		$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start, ($col_inc+1), "Subtree", $heading_format2);
	$worksheet->write($row_start+1, ($col_inc+1), "Freq", $heading_format2);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Words", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		my $ckey = $ct+$col_inc;
		my $col_alpha = $col_converter{$ckey};
		my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
		$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
		$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start, ($col_inc+1), "Subtree", $heading_format2);
	$worksheet->write($row_start+1, ($col_inc+1), "Freq", $heading_format2);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Counts", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		my $ckey = $ct+$col_inc;
		my $col_alpha = $col_converter{$ckey};
		my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
		$worksheet->write_formula( $row_start-2, $ckey, $sumform, $center_format );
		$worksheet->write($row_start-3, $ckey, "Sum", $heading_format1);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$col_inc++;
	
	my $spacing = scalar(keys %place_ctr);
	
	if($option) {

		## make sheet title
		$worksheet->write(0, 0, "MAIN Codes - Summary Stats by Speaker - 1 unit == 1 sentence", $heading_format2);
		
	
		$worksheet->set_column($code_rank_col, $code_rank_col, $code_rank_col_width);
		$worksheet->set_column($code_words_col, $code_words_col, $code_words_col_width);
		$worksheet->set_column($code_title_col, $code_title_col, $code_col_width);
		$worksheet->set_column($code_iname_ct_col, $code_iname_ct_col, $code_iname_ct_col_width);
		$worksheet->set_column($code_wd_mean_col, $code_wd_mean_col, $code_wd_mean_col_width);
		$worksheet->set_column($code_percent1_col, $code_percent1_col, $code_percent1_col_width);
		$worksheet->set_column($code_percent2_col, $code_percent2_col, $code_percent2_col_width);
		$worksheet->set_column($blank_col, $blank_col, $blank_col_width);

		if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} })) {
			say "[$me] prime codehref error...prime code list is not valid!";
			die "\tdying to fix at[".__LINE__."]\n";
		}
		my $prime_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes};
		say "[$me] prime codes loaded...size[".scalar(keys %$prime_codehref)."]" if $trace;
		
		my $start_col = $blank_col; ## increment cols after the blank col value
		my $padding = 1;
		my $rows = 0;
		my $row_ctr = $row_start + $row_headspace;
		if(scalar(keys %$prime_codehref)) {
			my $low_limit = 1;
			if(exists $post_text_config->{prime_code_count_low_limit} and $post_text_config->{prime_code_count_low_limit}) {
				$low_limit = $post_text_config->{prime_code_count_low_limit};
			}
			my $c_ctr = 0;
			my $_sorter = {};
			my $big_word_total = 0;
			foreach my $code (keys %$prime_codehref) {
				my $total = 0;
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count}) {
					$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count}) {
					$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count};
				}
#				my $total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{prime_code_stats}->{$code}->{lines}->{total}->{count};
				## check for valid 'total', skip if empty
				if(!$total) { 
					say "  [$me] setprime sorter hash...code[$code] code has NO total[".$total."]";
					next;
				}
				$_sorter->{$code} = $total;
				$big_word_total = $big_word_total + $total;
				#say "  [$me] setprime sorter hash...code[$code] total[".$total."]";
			}
			my $ckey = 2;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-1, $ckey, $sumform, $center_format );
			#$worksheet->write($row_start-1, 4, $big_word_total, $heading_format1);
			say "[$me] prime sorter hash...size[".scalar(keys %$_sorter)."]" if $trace;
			foreach my $code (sort { $_sorter->{$b} <=> $_sorter->{$a} } keys %$_sorter) {
				my $allcount = $_sorter->{$code};
				if($low_limit > $allcount) {
					say " [$me] prime code limiter, PER_code_stats, code[$code] code size too small[".$allcount."]";
					next;
				}
				my $text_code = $data_coding->{runlinks}->{code_form_mapping}->{$code};
				$worksheet->write($row_ctr, $code_title_col, $text_code);
#				$worksheet->write($row_ctr, $code_title_col, $code);
				my $allwords = 0;
				my $allinames = 0;
				my $allratio = 0;
				my $word_sum = 0;
				$worksheet->write($row_ctr, $code_rank_col, $allcount, $center_format);
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{tbase}) {
					$allwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{tbase}->{count};
					$c_ctr++;
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{subtree}) {
					$allwords = $allwords + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{subtree}->{count};
				}
				$worksheet->write($row_ctr, $code_words_col, $allwords, $center_format);

				foreach my $iname (keys %place_ctr) {
					if(!exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}) {
						next;
					}
					my $ct = $place_ctr{$iname};
					my $words_col = $start_col + $ct;
					my $count_col = $start_col + $spacing + $ct;
					my $chars_col = $start_col + $spacing + $spacing + $ct;
					my $inten_col = $start_col + $spacing + $spacing + $spacing + $ct;
					my $base_words_col = $start_col + $spacing + $spacing + $spacing + $spacing + $ct;
					my $base_count_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
#				my $words_col = $start_col + $ct;
#				my $count_col = $start_col + $spacing + $ct;
#				my $chars_col = $start_col + $spacing + $spacing + $ct;
#				my $inten_col = $start_col + $spacing + $spacing + $spacing + $ct;
					#my $base_words_col = $start_col + $spacing + $spacing + $spacing + $spacing + $ct;
					#my $base_count_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
					my $subtree_words_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
					my $subtree_count_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
					my $narrow_ratio_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
					my $disp_col = $start_col + $padding + $spacing + $spacing + $spacing  + $spacing + $spacing + $spacing + $spacing + $ct;
					my $tmean_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing  + $spacing + $spacing + $spacing + $spacing + $ct;
					
					my $subtree_count = 0;
					my $subtree_words = 0;
					my $tbase_count = 0;
					my $tcount = 0;
					my $chars = 0;
					my $words = 0;
					my $tbase_words = 0;
					my $intensity = 0;
					if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count}) {
						$tcount = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
						$tbase_count = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count}) {
						$tcount = $tcount + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
						$subtree_count = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count}) {
						$words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
						$tbase_words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count}) {
						$words = $words + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
						$subtree_words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
					}
					if($words) {
						$word_sum = $word_sum + $words;
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase}->{count}) {
						$chars = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{subtree}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{subtree}->{count}) {
						$chars = $chars + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{subtree}->{count};
					}
					if($tcount) {
						$worksheet->write($row_ctr, $count_col, $tcount);
					}
					if($tbase_count) {
						$worksheet->write($row_ctr, $base_count_col, $tbase_count);
					}
					if($subtree_count) {
						$worksheet->write($row_ctr, $subtree_count_col, $subtree_count);
					}
					if($words) {
						$worksheet->write($row_ctr, $words_col, $words, $center_format);
						$allinames++;
					}
					if($tbase_words) {
						$worksheet->write($row_ctr, $base_words_col, $tbase_words, $center_format);
					}
					if($subtree_words) {
						$worksheet->write($row_ctr, $subtree_words_col, $subtree_words);
					}
					if($chars) {
						$worksheet->write($row_ctr, $chars_col, $chars, $center_format);
					}

					if($tcount) {
						$intensity = $words / $tcount;
					}
					## give 2 digits to the right
					if($intensity=~/([\d]+)(\.[\d]+)/) {
						my $digits = $2 * 100;
						my $first = $1;
						my $second = '00';
						if($digits=~/([\d]+)\.([\d]*)/) {
							$second = $1;
							if($second < 10) {
								$second = "0" . $second;
							}
						}
						$intensity = $first . "." . $second;
					}
					if($intensity) {
						$worksheet->write($row_ctr, $inten_col, $intensity);
					}
				}
				my $cts = scalar(keys %place_ctr);
				my $iname_avg = 0;
				if($cts) {
					my $avg = $word_sum / $cts;
					$iname_avg = 0;
					if($allinames) {
						$iname_avg = $word_sum / $allinames;
					}
					if($avg) {
						$allratio = $iname_avg / $avg;
					}
					## give 2 digits to the right
					if($allratio=~/([\d]+)(\.[\d]+)/) {
						my $digits = $2 * 100;
						my $first = $1;
						my $second = '00';
						if($digits=~/([\d]+)([\.\d]*)/) {
							$second = $1;
							if($second < 10) {
								$second = "0" . $second;
							}
						}
						$allratio = $first . "." . $second;
					}
					## give 2 digits to the right
					if($iname_avg=~/([\d]+)(\.[\d]+)/) {
						my $digits = $2 * 100;
						my $first = $1;
						my $second = '00';
						if($digits=~/([\d]+)([\.\d]*)/) {
							$second = $1;
							if($second < 10) {
								$second = "0" . $second;
							}
						}
						$iname_avg = $first . "." . $second;
					} else {
						$iname_avg = $iname_avg . ".00";
					}
				}
				my $percent = $allwords / $big_word_total;

				## give 2 digits to the right
				if($percent=~/([\d]+)(\.[\d]+)/) {
					my $digits = $2 * 100;
					my $first = $1;
					my $second = '00';
					if($digits=~/([\d]+)([\.\d]*)/) {
						$second = $1;
						if($second < 10) {
							$second = "0" . $second;
						}
					}
					$percent = $first . "." . $second;
				} else {
					$percent = $iname_avg . ".00";
				}
				$percent = $percent . "%";

				$worksheet->write($row_ctr, $code_code_ctr_col, $c_ctr, $center_format);
				$worksheet->write($row_ctr, $code_cumm_percent_col, $percent, $center_format);
				$worksheet->write($row_ctr, $code_iname_ct_col, $allinames, $center_format);
#				$worksheet->write($row_ctr, $code_wd_mean_col, $iname_avg, $center_format);
#				$worksheet->write($row_ctr, $code_dis_ratio_col, $allratio, $center_format);

#				my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
#				$worksheet->write_formula( $end_main_sum_row, $s, $sumform, $center_format );
				
				$row_ctr++;
			}
		}
	
		return 1;
	}
	
	## make sheet title
	$worksheet->write(0, 0, "All Code Summary Stats by Speaker - 1 unit == 1 sentence", $heading_format2);
	$end_main_sum_row = 1600;

	$worksheet->set_column($col_inc, $col_inc, 4);
#	$worksheet->write($row_start, ($col_inc+1), "Dispersion - Narrow", $heading_format2);
#	$worksheet->write($row_start+1, ($col_inc+1), "Mean", $heading_format1);
#	$col_add = 0;
#	foreach my $iname (keys %place_ctr) {
#		my $ct = $place_ctr{$iname};
#		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
#		$col_add++;
#	}
#	$col_inc = $col_inc + $col_add;
#	$worksheet->write($row_start+1, ($col_inc+1), "% of All", $heading_format1);
#	$col_add = 0;
#	foreach my $iname (keys %place_ctr) {
#		my $ct = $place_ctr{$iname};
#		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
#		$col_add++;
#	}
#	$col_inc = $col_inc + $col_add;
#	$worksheet->write($row_start, ($col_inc+1), "Dispersion - Narrow:Medium:Wide", $heading_format2);
#	$worksheet->write($row_start+1, ($col_inc+1), "Counts", $heading_format2);
#	$col_add = 0;
#	foreach my $iname (keys %place_ctr) {
#		my $ct = $place_ctr{$iname};
#		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
#		$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), 15);
#		$col_add++;
#	}
#	$col_inc = $col_inc + $col_add;
#	$worksheet->write(0, ($col_inc+1), "Dispersion - Narrow:Medium:Wide", $heading_format2);
#	$worksheet->write($row_start+1, ($col_inc+1), "Mean Distance - Across All", $heading_format2);
#	$col_add = 0;
#	foreach my $iname (keys %place_ctr) {
#		my $ct = $place_ctr{$iname};
#		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
#		$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), 15);
#		$col_add++;
#	}
	say "[$me] wrote header, col_inc[$col_inc] col group size[$col_add] iname ct[".scalar(keys %place_ctr)."]";


	$worksheet->set_column($code_rank_col, $code_rank_col, $code_rank_col_width);
	$worksheet->set_column($code_words_col, $code_words_col, $code_words_col_width);
	$worksheet->set_column($code_title_col, $code_title_col, $code_col_width);
	$worksheet->set_column($code_iname_ct_col, $code_iname_ct_col, $code_iname_ct_col_width);
	$worksheet->set_column($code_wd_mean_col, $code_wd_mean_col, $code_wd_mean_col_width);
	$worksheet->set_column($code_percent1_col, $code_percent1_col, $code_percent1_col_width);
	$worksheet->set_column($code_percent2_col, $code_percent2_col, $code_percent2_col_width);
	$worksheet->set_column($blank_col, $blank_col, $blank_col_width);

	my $padding = 1;
	my $start_col = $blank_col; ## increment cols after the blank col value
	my $row_ctr = $row_start + $row_headspace;
	my $rows = 0;

	if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_list} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_list} })) {
		say "[$me] prime codehref error...prime code list is not valid!";
		die "\tdying to fix at[".__LINE__."]\n";
	}
	my $final_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_list};
	say "[$me] all codes (final) loaded...size[".scalar(keys %$final_codehref)."]" if $trace;	
	
	if(scalar(keys %$final_codehref)) {
		my $final_sorter = {};
		foreach my $code (keys %$final_codehref) {
			my $total = 0;
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count}) {
				$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
			}
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count}) {
				$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
			}
			$final_sorter->{$code} = $total;
		}
		my $c_ctr = 0;
		my $ckey = $start_col + $words_sum_start_offset; #49
		my $col_alpha = $col_converter{$ckey};
		$ckey = $ckey + 10;
		my $s_col = 2;
		my $col_alpha2 = $col_converter{$ckey};
		my $sumform = "=SUM(" . $col_alpha . ($row_start-1) . ":" . $col_alpha2 . ($row_start-1) . ")";
		$worksheet->write_formula( $row_start-2, $s_col, $sumform, $center_format );
#		foreach my $code (sort { $final_codectrhref->{$b} <=> $final_codectrhref->{$a} } keys %$final_codectrhref) {
		foreach my $code (sort { $final_sorter->{$b} <=> $final_sorter->{$a} } keys %$final_sorter) {
			my $text_code = $data_coding->{runlinks}->{code_form_mapping}->{$code};
			$worksheet->write($row_ctr, $code_title_col, $text_code);
#			$worksheet->write($row_ctr, $code_title_col, $code);
			my $allcount = $final_sorter->{$code};
			my $allwords = 0;
			my $allinames = 0;
			my $allratio = 0;
			my $word_sum = 0;
			$worksheet->write($row_ctr, $code_rank_col, $allcount, $center_format);
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count}) {
				$allwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
				$c_ctr++;
			}
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count}) {
				$allwords = $allwords + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
			}
			$worksheet->write($row_ctr, $code_words_col, $allwords, $center_format);
			
			foreach my $iname (keys %place_ctr) {
				if(!exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}) {
					next;
				}
				my $ct = $place_ctr{$iname};
				my $words_col = $start_col + $ct;
				my $count_col = $start_col + $spacing + $ct;
				my $chars_col = $start_col + $spacing + $spacing + $ct;
				my $inten_col = $start_col + $spacing + $spacing + $spacing + $ct;
				my $base_words_col = $start_col + $spacing + $spacing + $spacing + $spacing + $ct;
				my $base_count_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
				my $subtree_words_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
				my $subtree_count_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
#				my $narrow_ratio_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing + $ct;
#				my $disp_col = $start_col + $padding + $spacing + $spacing + $spacing  + $spacing + $spacing + $ct;
#				my $tmean_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing  + $spacing + $spacing + $ct;
				my $narrow_ratio_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
				my $disp_col = $start_col + $padding + $spacing + $spacing + $spacing  + $spacing + $spacing + $spacing + $spacing + $ct;
				my $tmean_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing  + $spacing + $spacing + $spacing + $spacing + $ct;
				
				my $tbase_count = 0;
				my $tbase_words = 0;
				my $subtree_count = 0;
				my $subtree_words = 0;
				my $tcount = 0;
				my $chars = 0;
				my $words = 0;
				my $intensity = 0;
#				if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count}) {
#					$tcount = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count};
#				}
#				if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count}) {
#					$words = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count};
#					$word_sum = $word_sum + $words;
#				}
#				if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count}) {
#					$chars = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count};
#				}

				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count}) {
					$tcount = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
					$tbase_count = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count}) {
					$tcount = $tcount + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
					$subtree_count = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
				}
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count}) {
					$words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
					$tbase_words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
				}
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count}) {
					$words = $words + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
					$subtree_words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
				}
				if($words) {
					$word_sum = $word_sum + $words;
				}
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase}->{count}) {
					$chars = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase}->{count};
				}
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{subtree}->{count} and $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{subtree}->{count}) {
					$chars = $chars + $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{subtree}->{count};
				}

				if($tcount) {
					$worksheet->write($row_ctr, $count_col, $tcount);
				}
				if($tbase_count) {
					$worksheet->write($row_ctr, $base_count_col, $tbase_count);
				}
				if($subtree_count) {
					$worksheet->write($row_ctr, $subtree_count_col, $subtree_count);
				}
				if($words) {
					$worksheet->write($row_ctr, $words_col, $words, $center_format);
					$allinames++;
				}
				if($tbase_words) {
					$worksheet->write($row_ctr, $base_words_col, $tbase_words, $center_format);
				}
				if($subtree_words) {
					$worksheet->write($row_ctr, $subtree_words_col, $subtree_words);
				}
				if($chars) {
					$worksheet->write($row_ctr, $chars_col, $chars, $center_format);
				}

				if($tcount) {
					$intensity = $words / $tcount;
				}
				## give 2 digits to the right
				if($intensity=~/([\d]+)(\.[\d]+)/) {
					my $digits = $2 * 100;
					my $first = $1;
					my $second = '00';
					if($digits=~/([\d]+)\.([\d]*)/) {
						$second = $1;
						if($second < 10) {
							$second = "0" . $second;
						}
					}
					$intensity = $first . "." . $second;
				}
				if($intensity) {
					$worksheet->write($row_ctr, $inten_col, $intensity);
				}
			}
			my $cts = scalar(keys %place_ctr);
			my $iname_avg = 0;
			if($cts) {
				my $avg = $word_sum / $cts;
				$iname_avg = 0;
				if($allinames) {
					$iname_avg = $word_sum / $allinames;
				}
#				if($avg) {
#					$allratio = $iname_avg / $avg;
#				}
				## give 2 digits to the right
#				if($allratio=~/([\d]+)(\.[\d]+)/) {
#					my $digits = $2 * 100;
#					my $first = $1;
#					my $second = '00';
#					if($digits=~/([\d]+)([\.\d]*)/) {
#						$second = $1;
#						if($second < 10) {
#							$second = "0" . $second;
#						}
#					}
#					$allratio = $first . "." . $second;
#				}
				## give 2 digits to the right
				if($iname_avg=~/([\d]+)(\.[\d]+)/) {
					my $digits = $2 * 100;
					my $first = $1;
					my $second = '00';
					if($digits=~/([\d]+)([\.\d]*)/) {
						$second = $1;
						if($second < 10) {
							$second = "0" . $second;
						}
					}
					$iname_avg = $first . "." . $second;
				} else {
					$iname_avg = $iname_avg . ".00";
				}
			}
			$worksheet->write($row_ctr, $code_code_ctr_col, $c_ctr, $center_format);
			$worksheet->write($row_ctr, $code_iname_ct_col, $allinames, $center_format);
#			$worksheet->write($row_ctr, $code_wd_mean_col, $iname_avg, $center_format);
#			$worksheet->write($row_ctr, $code_dis_ratio_col, $allratio, $center_format);
			$row_ctr++;
			$rows++;
		}

	} else {
		my %code_tcount = ();
		my %code_tchars = ();

		foreach my $iname (keys %place_ctr) {
			if(exists $statlinks->{$iname}) {
				if(exists $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}) {
	#		$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow} = 0;
					foreach my $code (keys %{ $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion} }) {
						#my $tcount = 0;
						my $tchars = 0;
						if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}) {
							if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} and $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count}) {
								$tchars = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count};
							}
						} 
						if(!exists $code_tchars{$code}) {
							$code_tchars{$code} = 0;
						}
						$code_tchars{$code} = $code_tchars{$code} + $tchars;
					}
				}
			} elsif(exists $href->{$iname}) {
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion}) {
					foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion} }) {
						my $tchars = 0;
						if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}) {
							if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} and $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count}) {
								$tchars = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count};
							}
						} 
						if(!exists $code_tchars{$code}) {
							$code_tchars{$code} = 0;
						}
						$code_tchars{$code} = $code_tchars{$code} + $tchars;
					}
				}
			}
		}
		
		my $start_col = $blank_col; ## increment cols after the blank col value
		my $padding = 1;
		my $rows = 0;
		my $row_ctr = $row_start + 3;
	#	foreach my $code (sort { $code_tcount{$b} <=> $code_tcount{$a} } keys %code_tcount) {
		foreach my $code (sort { $code_tchars{$b} <=> $code_tchars{$a} } keys %code_tchars) {
			## fetch a write-able code for spreadsheet
			my $text_code = $data_post_coding->{aquad_meta_coding}->{all_inames}->{code_form_mapping}->{$code};
			$worksheet->write($row_ctr, $code_title_col, $text_code);
			
			$worksheet->write($row_ctr, $code_rank_col, $code_tchars{$code} );
			foreach my $iname (keys %place_ctr) {
				my $ct = $place_ctr{$iname};
				my $count_col = $start_col + $ct;
				my $chars_col = $start_col + $spacing + $ct;
				my $inten_col = $start_col + $spacing  + $spacing + $ct;
				my $mean_col = $start_col + $padding + $spacing + $spacing + $spacing + $ct;
				my $narrow_ratio_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing + $ct;
				my $disp_col = $start_col + $padding + $spacing + $spacing + $spacing  + $spacing + $spacing + $ct;
				my $tmean_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing  + $spacing + $spacing + $ct;
				
				if(exists $statlinks->{$iname}) {
					if(exists $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}) {

						$worksheet->write($row_ctr, $count_col, $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{count}, $center_format);
						my $tcount = $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{count};
						my $chars = 0;
						my $freq = 0;
						if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} and $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count}) {
							$chars = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count};
						}
						if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count} and $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count}) {
							$freq = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count};
						}
						$worksheet->write($row_ctr, $chars_col, $chars);

						if(!$chars) {
							say "\t[$me] iname[$iname] missing chars value, code[$code]";
						}
						my $intensity = 0;
						if($tcount) {
							$intensity = $chars / $tcount;
						}
						## give 2 digits to the right
						if($intensity=~/([\d]+)(\.[\d]+)/) {
							my $digits = $2 * 100;
							my $first = $1;
							my $second = '00';
							if($digits=~/([\d]+)\.([\d]*)/) {
								$second = $1;
								if($second < 10) {
									$second = "0" . $second;
								}
							}
							$intensity = $first . "." . $second;
						}
						$worksheet->write($row_ctr, $inten_col, $intensity);

						my $mean = 0;
						if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow}) {
							$mean = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow};
						}
						if(!$mean) {
							## nothing meaningful to output...
							next;
						}
						## give 2 digits to the right
						if($mean=~/([\d]+)(\.[\d]+)/) {
							my $first = $1;
							
							my $digits = $2;
							if($digits) {
								$digits = $digits * 1000;
							}
							my $second = '00';
							if($digits=~/([\d]+)\.([\d]*)/) {
								$second = $1;
								if($second < 10) {
									$second = "00" . $second;
								} elsif($second < 100) {
									$second = "0" . $second;
								}
							}
							$mean = $first . "." . $second;
						}
						$worksheet->write($row_ctr, $mean_col, $mean);

						my $n_ct = $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{count};
						if(!$n_ct) { $n_ct = 0; }
						my $m_ct = $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{count};
						if(!$m_ct) { $m_ct = 0; }
						my $w_ct = $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{count};
						if(!$w_ct) { $w_ct = 0; }
						my $ratio = 0;
						if($n_ct) {
							$ratio = (100 * $n_ct) / ($n_ct + $m_ct + $w_ct);
							if($ratio=~/([\d]+)(\.[\d]+)/) {
								$ratio = $1;
								my $digits = $2 * 10;
								if($digits > 5) {
									$ratio++;
								}
							}
						}
						$worksheet->write($row_ctr, $narrow_ratio_col, $ratio . "%", $center_format);
						
						my $counts = $n_ct . ':' . $m_ct . ':' . $w_ct;
						$worksheet->write($row_ctr, $disp_col, $counts, $center_format);

						my $mean2 = $statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean};
						if($mean2=~/([\d]+)(\.[\d]+)/) {
							my $first = $1;
							my $digits = $2 * 10;
							my $add = '0';
							if($digits=~/([\d]+)(\.[\d]+)/) {
								$add = $1;
							}
							$mean2 = $first . "." . $add;
						}
						$worksheet->write($row_ctr, $tmean_col, $mean2);
					
					}
				} elsif(exists $href->{$iname}) {
				#foreach my $iname (keys %$href) {
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}) {

						my $ct = $place_ctr{$iname};
						my $count_col = $start_col + $ct;
						my $chars_col = $start_col + $spacing + $ct;
						my $inten_col = $start_col + $spacing  + $spacing + $ct;
						my $mean_col = $start_col + $padding + $spacing + $spacing + $spacing + $ct;
						my $narrow_ratio_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing + $ct;
						my $disp_col = $start_col + $padding + $spacing + $spacing + $spacing  + $spacing + $spacing + $ct;
						my $tmean_col = $start_col + $padding + $spacing + $spacing + $spacing + $spacing  + $spacing + $spacing + $ct;

						$worksheet->write($row_ctr, $count_col, $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{count}, $center_format);
						my $tcount = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{count};
						#my $chars = $data_coding->{$iname}->{re_codes}->{code_stats}->{$code}->{chars}->{total_count};
						my $chars = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count};
						my $freq = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count};
						$worksheet->write($row_ctr, $chars_col, $chars);

						if(!$chars) {
							say "\t[$me] iname[$iname] missing chars value, code[$code]";
						}
						my $intensity = 0;
						if($tcount) {
							$intensity = $chars / $tcount;
						}
						## give 2 digits to the right
						if($intensity=~/([\d]+)(\.[\d]+)/) {
							my $digits = $2 * 100;
							my $first = $1;
							my $second = '00';
							if($digits=~/([\d]+)\.([\d]*)/) {
								$second = $1;
								if($second < 10) {
									$second = "0" . $second;
								}
							}
							$intensity = $first . "." . $second;
						}
						$worksheet->write($row_ctr, $inten_col, $intensity);

						my $mean = 0;
						if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow}) {
							$mean = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow};
						}
						if(!$mean) {
							## nothing meaningful to output...
							next;
						}
						## give 2 digits to the right
						if($mean=~/([\d]+)(\.[\d]+)/) {
							my $first = $1;
							
							my $digits = $2;
							if($digits) {
								$digits = $digits * 1000;
							}
							my $second = '00';
							if($digits=~/([\d]+)\.([\d]*)/) {
								$second = $1;
								if($second < 10) {
									$second = "00" . $second;
								} elsif($second < 100) {
									$second = "0" . $second;
								}
							}
							$mean = $first . "." . $second;
						}
						$worksheet->write($row_ctr, $mean_col, $mean);

						my $n_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{count};
						if(!$n_ct) { $n_ct = 0; }
						my $m_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{count};
						if(!$m_ct) { $m_ct = 0; }
						my $w_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{count};
						if(!$w_ct) { $w_ct = 0; }
						my $ratio = 0;
						if($n_ct) {
							$ratio = (100 * $n_ct) / ($n_ct + $m_ct + $w_ct);
							if($ratio=~/([\d]+)(\.[\d]+)/) {
								$ratio = $1;
								my $digits = $2 * 10;
								if($digits > 5) {
									$ratio++;
								}
							}
						}
						$worksheet->write($row_ctr, $narrow_ratio_col, $ratio . "%", $center_format);

						my $counts = $n_ct . ':' . $m_ct . ':' . $w_ct;
						$worksheet->write($row_ctr, $disp_col, $counts, $center_format);

						my $mean2 = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean};
						if($mean2=~/([\d]+)(\.[\d]+)/) {
							my $first = $1;
							my $digits = $2 * 10;
							my $add = '0';
							if($digits=~/([\d]+)(\.[\d]+)/) {
								$add = $1;
							}
							$mean2 = $first . "." . $add;
						}
						$worksheet->write($row_ctr, $tmean_col, $mean2);

					}
				}
			}
			$row_ctr++;
			$rows++;
		}
	}
	
	say "[$me] wrote to *per_code_stats* sheet, for [".scalar(keys %place_ctr)."] inames, [$rows] rows of codes";
	foreach my $iname (keys %place_ctr) {
#		$run_status->{active_xls_iname_percodestats}->{$iname} = $place_ctr{$iname};
	}

	return $taskid;
}
sub write_aspect_criticals_tables {
	my ($cat,$taskid,$write_choice,$worksheet,$href,$heading_format1,$heading_format2,$center_format,$shade_format,$trace) = @_;
	my $me = "WRITE-ASPSTS-CRIT";
	$me = $me . "][taskid:$taskid][cat:$cat";
	print "= [$my_shortform_server_type][$me] write critical aspects\n" if $trace;

	my $aspect_title_col = 1;
	my $aspect_col_width = 60;
	my $blank_col = 2;
	my $header_row_start = 2;
	my $crawlspace_headroom = 14;
	my $per_iname_col_shift = 9;
	my $spacer_col = 8;
	my $spacer_col_width = 20;
	my $aspect_data_width = 9;
	if($write_choice) {
		$aspect_data_width = 12;
	}

	if(!exists $data_stats_aspects->{by_iname}) {
		say "[$my_shortform_server_type][$me] Critical Failure writing criticals....missing hash[data_stats_aspects] or hashkey{by_iname}";
		die "\tdying to fix, line[".__LINE__."]\n";
	}
	my $stat_aspects = $data_stats_aspects->{by_iname};

	my %place_ctr = ();
	my $ct = 1;
#	foreach my $iname (keys %$href) {
	foreach my $iname (keys %{ $run_status->{active_5_done_code_stating_iname} }) {
		if($run_status->{active_5_done_code_stating_iname}->{$iname}) {
			$place_ctr{$iname} = $ct;
			$ct++;
		}
	}
	foreach my $iname (keys %$stat_aspects) {
		if(!exists $place_ctr{$iname}) {
			$place_ctr{$iname} = $ct;
			$ct++;
		}
	}

	my %aspect_tcount = ();
	my %aspect_ct = ();
	
	if(!$write_choice) {

		## make header rows
		my $col_inc = $aspect_title_col;
		$worksheet->write($header_row_start, $col_inc, "Aspect Name", $heading_format1);
		$worksheet->write($header_row_start, $col_inc+1, "Freq", $heading_format1);
		$worksheet->write($header_row_start+1, $col_inc+1, "Count", $heading_format1);
		$worksheet->write($header_row_start, $col_inc+2, "Freq", $heading_format1);
		$worksheet->write($header_row_start+1, $col_inc+2, "Words", $heading_format1);
		$worksheet->write($header_row_start, $col_inc+3, "Total", $heading_format1);
		$worksheet->write($header_row_start+1, $col_inc+3, "Ratings", $heading_format1);
		$worksheet->write($header_row_start, $col_inc+4, "Mean", $heading_format1);
		$worksheet->write($header_row_start+1, $col_inc+4, "Rating", $heading_format1);
		$worksheet->write($header_row_start, $col_inc+5, "Rated-5", $heading_format1);
		$worksheet->write($header_row_start+1, $col_inc+5, "Words", $heading_format1);
		$worksheet->write($header_row_start, $col_inc+6, "Rated-5", $heading_format1);
		$worksheet->write($header_row_start+1, $col_inc+6, "Rating", $heading_format1);
		$col_inc = $per_iname_col_shift;
		my $col_add = 0;
		foreach my $iname (keys %place_ctr) {
			my $ct = $place_ctr{$iname};
			$worksheet->write($header_row_start-1, ($ct+$col_inc), $iname, $heading_format1);
			$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), $aspect_data_width);
			$worksheet->write($header_row_start, ($col_inc+$ct), "Freq", $heading_format1);
			$worksheet->write($header_row_start+1, ($col_inc+$ct), "Words", $heading_format1);
			$col_add++;
		}
		$col_inc = $col_inc + $col_add;
		$col_add = 0;
		foreach my $iname (keys %place_ctr) {
			my $ct = $place_ctr{$iname};
			$worksheet->write($header_row_start-1, ($ct+$col_inc), $iname, $heading_format1);
			$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), $aspect_data_width);
			$worksheet->write($header_row_start, ($col_inc+$ct), "Total", $heading_format1);
			$worksheet->write($header_row_start+1, ($col_inc+$ct), "Ratings", $heading_format1);
			$col_add++;
		}
		$col_inc = $col_inc + $col_add;
		$col_add = 0;
		foreach my $iname (keys %place_ctr) {
			my $ct = $place_ctr{$iname};
			$worksheet->write($header_row_start-1, ($ct+$col_inc), $iname, $heading_format1);
			$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), $aspect_data_width);
			$worksheet->write($header_row_start, ($col_inc+$ct), "Freq", $heading_format1);
			$worksheet->write($header_row_start+1, ($col_inc+$ct), "Count", $heading_format1);
			$col_add++;
		}
		$col_inc = $col_inc + $col_add;
		$col_add = 0;
		foreach my $iname (keys %place_ctr) {
			my $ct = $place_ctr{$iname};
			$worksheet->write($header_row_start-1, ($ct+$col_inc), $iname, $heading_format1);
			$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), $aspect_data_width);
			$worksheet->write($header_row_start, ($col_inc+$ct), "Mean", $heading_format1);
			$worksheet->write($header_row_start+1, ($col_inc+$ct), "Rating", $heading_format1);
			$col_add++;
		}
		$col_inc = $col_inc + $col_add;
		$col_add = 0;
		foreach my $iname (keys %place_ctr) {
			my $ct = $place_ctr{$iname};
			$worksheet->write($header_row_start-1, ($ct+$col_inc), $iname, $heading_format1);
			$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), $aspect_data_width);
			$worksheet->write($header_row_start, ($col_inc+$ct), "Freq", $heading_format1);
			$worksheet->write($header_row_start+1, ($col_inc+$ct), "Chars", $heading_format1);
			$col_add++;
		}
		$col_inc = $col_inc + $col_add;
		$col_add = 0;
		foreach my $iname (keys %place_ctr) {
			my $ct = $place_ctr{$iname};
			$worksheet->write($header_row_start-1, ($ct+$col_inc), $iname, $heading_format1);
			$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), $aspect_data_width);
			$worksheet->write($header_row_start, ($col_inc+$ct), "Rated 5", $heading_format1);
			$worksheet->write($header_row_start+1, ($col_inc+$ct), "Words", $heading_format1);
			$col_add++;
		}
		$col_inc = $col_inc + $col_add;
		$col_add = 0;
		foreach my $iname (keys %place_ctr) {
			my $ct = $place_ctr{$iname};
			$worksheet->write($header_row_start-1, ($ct+$col_inc), $iname, $heading_format1);
			$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), $aspect_data_width);
			$worksheet->write($header_row_start, ($col_inc+$ct), "Rated 5", $heading_format1);
			$worksheet->write($header_row_start+1, ($col_inc+$ct), "Ratings", $heading_format1);
			$col_add++;
		}
		

		$worksheet->set_column(0, 0, 8);
		$worksheet->set_column($aspect_title_col, $aspect_title_col, $aspect_col_width);
#		$worksheet->set_column(2, 2, 15);
		$worksheet->set_column($spacer_col, $spacer_col, $spacer_col_width);

		my $actr = 1;
		
		my %aspect_ranker = ();
		if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}) {
			foreach my $aspect (keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats} }) {
				$aspect_ranker{$aspect} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{lines}->{total}->{count};
			}
		}

		my $spacing = scalar(keys %place_ctr);
		my $row_adjust = 1;

		my $left_start_col = 0;
		my $rows = 0;
		my $row_ctr = $header_row_start + 3;

		$rows = 0;
		my $ctr = 1;
		my $_col_ctr = 0;
		
		my $start_col = $_col_ctr + $per_iname_col_shift;
		my $start_main_sums = 0;
		my $end_main_sums = 0;
		my $start_main_sum_row = $row_ctr + 1;
		my $end_main_sum_row = 0;
		my $__row = $row_ctr + $row_adjust;
		foreach my $aspect (sort { $aspect_ranker{$b} <=> $aspect_ranker{$a} } keys %aspect_ranker) {
			$worksheet->write($row_ctr, $left_start_col, $ctr, $center_format);
			$worksheet->write($row_ctr, $left_start_col+1, $aspect);
			$worksheet->write($row_ctr, $left_start_col+2, $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{lines}->{total}->{count}, $center_format);
			$start_main_sums = $left_start_col+2;
			$worksheet->write($row_ctr, $left_start_col+3, $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{words}->{total}->{integral_sum}, $center_format);
			$worksheet->write($row_ctr, $left_start_col+4, $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{ratings}->{total}->{count}, $center_format);
			$__row = $row_ctr + $row_adjust;
			my $mean_rating = $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{ratings}->{total}->{count} / $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{lines}->{total}->{count};
			## give 2 digits to the right
			if($mean_rating=~/([\d]+)(\.[\d]+)/) {
				my $digits = $2 * 100;
				my $first = $1;
				my $second = '00';
				if($digits=~/([\d]+)\.([\d]*)/) {
					$second = $1;
					if($second < 10) {
						$second = "0" . $second;
					}
				}
				$mean_rating = $first . "." . $second;
			}
			$worksheet->write($row_ctr, $left_start_col+5, $mean_rating, $center_format);
			$worksheet->write($row_ctr, $left_start_col+6, $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{words_5}->{total}->{integral_sum}, $center_format);
			$worksheet->write($row_ctr, $left_start_col+7, $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{ratings_5}->{total}->{count}, $center_format);
			$end_main_sums = $left_start_col+7;
			$end_main_sum_row = $row_ctr + 1;

			foreach my $iname (sort{$place_ctr{$a} <=> $place_ctr{$b}} keys %place_ctr) {
				if(exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}) {
					if(exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}) {
						my $ct = $place_ctr{$iname};
						my $words_col = $start_col + $ct;
						my $ratings_col = $start_col + $spacing + $ct;
						my $count_col = $start_col + $spacing + $spacing + $ct;
						my $mean_col = $start_col + $spacing + $spacing + $spacing + $ct;
						my $chars_col = $start_col + $spacing + $spacing + $spacing + $spacing + $ct;
						my $words5_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;
						my $ratings5_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + $ct;

						my $count = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{lines}->{total}->{count};
						my $sum_ratings = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total}->{count};
						my $words = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total}->{count};
						my $words5 = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_5}->{integral_sum};
						my $ratings5 = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_5}->{count};
						my $mean_rating = $sum_ratings / $count;

						$worksheet->write($row_ctr, $count_col, $count, $center_format);
						$worksheet->write($row_ctr, $words_col, $words, $center_format);
						$worksheet->write($row_ctr, $ratings_col, $sum_ratings, $center_format);

						## give 2 digits to the right
						if($mean_rating=~/([\d]+)(\.[\d]+)/) {
							my $digits = $2 * 100;
							my $first = $1;
							my $second = '00';
							if($digits=~/([\d]+)\.([\d]*)/) {
								$second = $1;
								if($second < 10) {
									$second = "0" . $second;
								}
							}
							$mean_rating = $first . "." . $second;
						}

						$worksheet->write($row_ctr, $mean_col, $mean_rating, $center_format);

						my $chars = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{chars}->{total}->{count};
						$worksheet->write($row_ctr, $chars_col, $chars, $center_format);
						
						$worksheet->write($row_ctr, $words5_col, $words5, $center_format);
						$worksheet->write($row_ctr, $ratings5_col, $ratings5, $center_format);
					}
				}
			}
			$row_ctr++;
			$aspect_ct{$aspect} = $ctr;
			$ctr++;
		}

		my $_sub1_row = $__row + 1;
		my $_sub2_row = $__row + 2;
		my $_col = $left_start_col+4;
		my $_col_alpha = $col_converter{$_col};
		my $all_ratings_cell = $_col_alpha . $_sub1_row;
		$_col = $left_start_col+6;
		$_col_alpha = $col_converter{$_col};
		my $all_words5_cell = $_col_alpha . $_sub1_row;
		$_col = $left_start_col+7;
		$_col_alpha = $col_converter{$_col};
		my $all_ratings5_cell = $_col_alpha . $_sub1_row;
		
		my $start_words_col = $start_col + 1;
		my $end_ratings_col = $start_col + $spacing + scalar(keys %place_ctr);
		my $start_words5_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + 1;
		my $start_ratings5_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + 1;
		my $end_words5_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + scalar(keys %place_ctr);
		my $end_ratings5_col = $start_col + $spacing + $spacing + $spacing + $spacing + $spacing + $spacing + scalar(keys %place_ctr);

		if($end_main_sums) {
			for (my $s=$start_main_sums; $s<$end_main_sums+1; $s++) {
				my $col_alpha = $col_converter{$s};
				my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
				$worksheet->write_formula( $end_main_sum_row, $s, $sumform, $center_format );
			
#				$worksheet->write_formula( 2, 0, '=SUM(B1:B5)' );
			}
		}
		### make all ratings per word value
		my $_ratings_col = $_col = $left_start_col+4;
		$_col_alpha = $col_converter{$_col};
		my $all_ratings_per_word_cell = $_col_alpha . $_sub2_row;
		my $_words_col = $_col = $left_start_col+3;
		$_col_alpha = $col_converter{$_col};
		my $all_words_per_rating_cell = $_col_alpha . $_sub2_row;
		my $all_words_cell = $_col_alpha . $_sub1_row;
		my $allform = "=" . $all_words_cell . " / " . $all_ratings_cell;
		$worksheet->write_formula( $__row + 1, $_words_col, $allform, $center_format );
		my $allform2 = "=" . $all_ratings_cell . " / " . $all_words_cell;
		$worksheet->write_formula( $__row + 1, $_ratings_col, $allform2, $center_format );

		my $_ratings5_col = $_col = $left_start_col+7;
		$_col_alpha = $col_converter{$_col};
		my $all_ratings5_per_word5_cell = $_col_alpha . ($__row + 1);
		my $_words5_col = $_col = $left_start_col+6;
		$_col_alpha = $col_converter{$_col};
		my $all_words5_per_rating5_cell = $_col_alpha . ($__row + 1);

		my $allform3 = "=" . $all_words5_cell . " / " . $all_ratings5_cell;
		$worksheet->write_formula( $__row + 1, $_words5_col, $allform3, $center_format );
		my $allform4 = "=" . $all_ratings5_cell . " / " . $all_words5_cell;
		$worksheet->write_formula( $__row + 1, $_ratings5_col, $allform4, $center_format );
##		$_col = $left_start_col+3;
		
		if($start_words_col) {
			for (my $s=$start_words_col; $s<$end_ratings_col+1; $s++) {
				my $col_alpha = $col_converter{$s};
				my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
				$worksheet->write_formula( $end_main_sum_row, $s, $sumform, $center_format );
			}
		}
		if($start_words5_col) {
			for (my $s=$start_words5_col; $s<$end_ratings5_col+1; $s++) {
				my $col_alpha = $col_converter{$s};
				my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
				$worksheet->write_formula( $end_main_sum_row, $s, $sumform, $center_format );
			}
		}
		
		my $_sum_ptr = 1;
		my $avg_ratings_per_word = 0;
		if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{words}->{total}->{integral_sum} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{words}->{total}->{integral_sum}) {
			$avg_ratings_per_word = $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings}->{total}->{count} / $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{words}->{total}->{integral_sum};
		}

		my $add_for_w5 = scalar(keys %place_ctr) * 4;
		my $add_for_r5 = scalar(keys %place_ctr) * 5;
		$row_ctr = $row_ctr + 2;

		## write summary values at the bottom of the 'words" matrix block
		$worksheet->write($row_ctr+1, $spacer_col, "Summed Words",);
		$worksheet->write($row_ctr+2, $spacer_col, "Summed Ratings",);
		$worksheet->write($row_ctr+3, $spacer_col, "Ratings per Spkr word",);
		$worksheet->write($row_ctr+4, $spacer_col, "Spkr ratings to all ratings",);

		$worksheet->write($row_ctr+4, $spacer_col+1, $all_ratings_cell,);

		$worksheet->write($row_ctr+5, $spacer_col, "Spkr ratings/word to all r/wd",);
		$worksheet->write($row_ctr+6, $spacer_col, "Words per Spkr rating",);
		$worksheet->write($row_ctr+7, $spacer_col, "Spkr words to all words",);
		$worksheet->write($row_ctr+8, $spacer_col, "Spkr words/rating to all wds/r",);
		$worksheet->write($row_ctr+9, $spacer_col, "Rated 5 words to Spkr words",);
		$worksheet->write($row_ctr+10, $spacer_col, "Ratings 5 to rated 5 words",);
		$worksheet->write($row_ctr+11, $spacer_col, "Ratings 5 to Spkr ratings",);
		$worksheet->write($row_ctr+12, $spacer_col, "Spkr 5 ratings/wds to all 5 r/wd",);
		$worksheet->write($row_ctr+13, $spacer_col, "Spkr 5 words to all 5 words",);
		foreach my $iname (sort{$place_ctr{$a} <=> $place_ctr{$b}} keys %place_ctr) {
#		foreach my $iname (keys %place_ctr) {
			my $base_col = $start_col + $_sum_ptr;
			my $col_alpha = $col_converter{$base_col};
			$worksheet->write($row_ctr+1, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total}->{integral_sum}, $center_format);
			$worksheet->write($row_ctr+2, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total}->{count}, $center_format);
			my $divform = "=" . $col_alpha . ($row_ctr + 2 + $row_adjust) . " / "  . $col_alpha . ($row_ctr + 1 + $row_adjust);
			$worksheet->write_formula( $row_ctr+3, $base_col, $divform, $center_format );
#			$worksheet->write($row_ctr+3, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_per_iname_word}, $center_format);
			my $divform2 = "=" . $col_alpha . ($row_ctr + 2 + $row_adjust) . " / "  . $all_ratings_cell;
			$worksheet->write_formula( $row_ctr+4, $base_col, $divform2, $center_format );
#			$worksheet->write($row_ctr+4, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_to_total_aspects_ratings}, $center_format);
			my $divform3 = "=" . $col_alpha . ($row_ctr + 3 + $row_adjust) . " / "  . $all_ratings_per_word_cell;
			$worksheet->write_formula( $row_ctr+5, $base_col, $divform3, $center_format );
#			$worksheet->write($row_ctr+5, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{hyper}->{iname_ratings_per_word_to_total_ratings_per_word}, $center_format);
			my $divform4 = "=" . $col_alpha . ($row_ctr + 1 + $row_adjust) . " / "  . $col_alpha . ($row_ctr + 2 + $row_adjust);
			$worksheet->write_formula( $row_ctr+6, $base_col, $divform4, $center_format );
#			$worksheet->write($row_ctr+6, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_unit_iname_rating}, $center_format);
			my $divform5 = "=" . $col_alpha . ($row_ctr + 1 + $row_adjust) . " / "  . $all_words_cell;
			$worksheet->write_formula( $row_ctr+7, $base_col, $divform5, $center_format );
#			$worksheet->write($row_ctr+7, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_total_aspects_words}, $center_format);
			my $divform6 = "=" . $col_alpha . ($row_ctr + 6 + $row_adjust) . " / "  . $all_words_per_rating_cell;
			$worksheet->write_formula( $row_ctr+8, $base_col, $divform6, $center_format );
#			$worksheet->write($row_ctr+8, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{hyper}->{iname_words_per_unit_to_total_words_per_unit}, $center_format);
			my $w5_base_col = $start_words5_col + $_sum_ptr - 1; ## start_col is already point to first col....
			my $w5_col_alpha = $col_converter{$w5_base_col};
			my $r5_base_col = $start_ratings5_col + $_sum_ptr - 1;
			my $r5_col_alpha = $col_converter{$r5_base_col};
#			my $_allcol = $w5_col_alpha . $row_ctr;
			my $divform7 = "=" . $w5_col_alpha . ($row_ctr - 1 + $row_adjust) . " / "  . $col_alpha . ($row_ctr + 1 + $row_adjust);
			$worksheet->write($row_ctr+9, $base_col, $divform7, $center_format);
#			my $divform7 = "=" . $col_alpha . ($row_ctr + 2 + $row_adjust) . " / "  . $col_alpha . ($row_ctr + 1 + $row_adjust);
			my $divform8 = "=" . $r5_col_alpha . ($row_ctr - 1 + $row_adjust) . " / "  . $w5_col_alpha . ($row_ctr - 1 + $row_adjust);
			$worksheet->write_formula( $row_ctr+10, $base_col, $divform8, $center_format );
#			$worksheet->write($row_ctr+10, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_iname5_word}, $center_format);
			my $divform9 = "=" . $r5_col_alpha . ($row_ctr - 1 + $row_adjust) . " / "  . $col_alpha . ($row_ctr + 2 + $row_adjust);
			$worksheet->write_formula( $row_ctr+11, $base_col, $divform9, $center_format );
#			$worksheet->write($row_ctr+11, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_total_iname_ratings}, $center_format);
			my $divform10 = "=" . $col_alpha . ($row_ctr + 10 + $row_adjust) . " / "  . $all_ratings5_per_word5_cell;
			$worksheet->write($row_ctr+12, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{ratings5_per_word_to_all_ratings5_per_word}, $center_format);
			my $divform11 = "=" . $w5_col_alpha . ($row_ctr - 1 + $row_adjust) . " / "  . $all_words5_cell;
			$worksheet->write_formula( $row_ctr+13, $base_col, $divform11, $center_format );
#			$worksheet->write($row_ctr+13, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{words5_per_iname_words_to_all_words5}, $center_format);

			$worksheet->write($row_ctr+14, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{words5_per_total_iname_words}, $center_format);
			$worksheet->write($row_ctr+15, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_iname5_word}, $center_format);
			$worksheet->write($row_ctr+16, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_total_iname_ratings}, $center_format);
			$worksheet->write($row_ctr+17, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{ratings5_per_word_to_all_ratings5_per_word}, $center_format);
			$worksheet->write($row_ctr+18, $base_col, $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{words5_per_iname_words_to_all_words5}, $center_format);
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{ratings5_per_word_to_all_ratings5_per_word} = ($aspects_5_ratings / $aspects_5_words) / $all_ratings5_to_words5_ratio;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{words5_per_iname_words_to_all_words5} = ($aspects_5_words / $aspects_words) / $all_words5_to_all_words_ratio;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{words5_per_total_iname_words} = $aspects_5_words / $aspects_words;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_iname5_word} = $aspects_5_ratings / $aspects_5_words;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_total_iname_ratings} = $aspects_5_ratings / $aspects_ratings;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_unit_iname_rating} = $aspects_words / $aspects_ratings;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_total_aspects_words} = $aspects_words / $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{words}->{total}->{integral_sum};
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{hyper}->{iname_words_per_unit_to_total_words_per_unit} = ($aspects_words / $aspects_ratings) / $all_words_to_ratings_ratio;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_per_iname_word} = $aspects_ratings / $aspects_words;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_to_total_aspects_ratings} = $aspects_ratings / $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings}->{total}->{count};
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{hyper}->{iname_ratings_per_word_to_total_ratings_per_word} = ($aspects_ratings / $aspects_words) / $all_ratings_to_words_ratio;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{words5_per_unit_iname5_rating} = $aspects_5_words / $aspects_5_ratings;
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{words5_per_unit_to_iname_words_per_unit} = ($aspects_5_words / $aspects_5_ratings) / $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_unit_iname_rating};
#			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{ratings5_per_word_to_iname_ratings_per_word} = ($aspects_5_ratings / $aspects_5_words) / $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_per_iname_word};
#			$worksheet->write($row_ctr+3, $base_col, $ratio, $center_format);
			$_sum_ptr++;
		}
	
	} else {

		my $row_ctr = $header_row_start + 0;
		my $rows = $row_ctr;

		my %aspect_ranker = ();
		if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}) {
			foreach my $aspect (keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats} }) {
				$aspect_ranker{$aspect} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{lines}->{total}->{count};
			}
		}
		my $ctr = 1;
		foreach my $aspect (sort { $aspect_ranker{$b} <=> $aspect_ranker{$a} } keys %aspect_ranker) {
			$aspect_ct{$aspect} = $ctr;
			$ctr++;
		}

#		my $codes_row_start = $rows + $crawlspace_headroom + 3;
		my $codes_row_start = $rows + 1;
		
		my $row_c_ctr = 0;
		$worksheet->write($codes_row_start+1, 0, "T-S Key", $heading_format1);
		$worksheet->write($codes_row_start, 1, "Critical Text Segments ~~", $heading_format1);
		$worksheet->write($codes_row_start+1, 1, "Aspect", $heading_format1);
		$worksheet->write($codes_row_start+1, 3, "Rank", $heading_format1);
		$worksheet->write($codes_row_start+1, 4, "Speaker", $heading_format1);
		$worksheet->write($codes_row_start+1, 5, "Rating::Aspect", $heading_format1);

		$worksheet->set_column(0, 0, 8);
		$worksheet->set_column($aspect_title_col, $aspect_title_col, $aspect_col_width);
		$worksheet->set_column(2, 2, 15);

		$row_c_ctr = $row_c_ctr + 2;

		if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{critical_list} and scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{critical_list} })) {
			my $super_sorter = {};
			my %sorter = ();
			my %supersorter = ();
			my $re_sorter = {};
			my $sort_me = $data_post_coding->{aquad_meta_coding}->{all_inames}->{critical_list};
			my $sort_ctr = 1;
			my %much_better_sorter = ();
			foreach my $akey (sort{$sort_me->{$b} <=> $sort_me->{$a}} keys %{ $sort_me }) {
				my ($iname,$tskey) = split("__",$akey);
#			$sorter{$tskey} = $data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_rank}; # . "_" . $tskey;
#			$re_sorter->{ $data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_rank} }->{$tskey} = $tskey;
#			$super_sorter->{$tskey}->{ $data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_rank} } = $tskey;
				$much_better_sorter{$sort_ctr}{tskey} = $tskey;
				$much_better_sorter{$sort_ctr}{iname} = $iname;
				$much_better_sorter{$sort_ctr}{rrating} = $sort_me->{$akey};
				$sort_ctr++;
			}
			foreach my $ikey (sort { $b <=> $a } keys %$re_sorter) {
				my $newval = $ikey * 100;
				if(scalar($re_sorter->{$ikey}) > 1) {
					my $ictr = 1;
					foreach my $ts_key (sort {$a cmp $b} keys %{ $re_sorter->{$ikey} }) {
						$supersorter{$ts_key} = $newval - $ictr;
						$ictr++;
					}
					next;
				}
				foreach my $ts_key (keys %{ $re_sorter->{$ikey} }) {
					$supersorter{$ts_key} = $newval;
				}
			}
#		foreach my $tskey (sort { $supersorter{$b} <=> $supersorter{$a} } keys %supersorter) {
		foreach my $index (sort { $a <=> $b } keys %much_better_sorter) {
#			my $rank = $key_href->{$tskey}->{by_rank};
#			my $iname = $key_href->{$tskey}->{by_iname};
#			my $text = $key_href->{$tskey}->{sentence_text};
			my $iname = $much_better_sorter{$index}{iname};
			my $tskey = $much_better_sorter{$index}{tskey};
			my $rank = $much_better_sorter{$index}{rrating};
			if(!$iname or !$tskey) {
				say "[$me] oh bugger...invalid iname or tskey at index[$index] xls output";
				die "\tdying to fix at line[".__LINE__."]\n";
			}
#			my $rank = $data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_rank};
#			my $iname = $data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_iname};
#			my $text = $data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{sentence_text};
			my $text = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{sentence};
			$worksheet->write($row_c_ctr + $codes_row_start, 0, $tskey, $center_format);
			$worksheet->write($row_c_ctr + $codes_row_start, 1, $text);

#			$worksheet->write($row_c_ctr + $codes_row_start, 2, $supersorter{$tskey});

			$worksheet->write($row_c_ctr + $codes_row_start, 3, $rank, $center_format);
			$worksheet->write($row_c_ctr + $codes_row_start, 4, $iname, $center_format);
			
			my $col_start = 4;
#			$tcodes = $data_coding->{$iname}->{re_codes}->{sentences};
			foreach my $aspect (keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{aspects} }) {
#			foreach my $aspect (keys %{ $stat_aspects->{$iname}->{re_aspects}->{ratings}->{critical}->{by_tskey}->{$tskey}->{by_aspect} }) {
#				my $rating = $stat_aspects->{$iname}->{re_aspects}->{ratings}->{critical}->{by_tskey}->{$tskey}->{by_aspect}->{$aspect}->{rating};
				my $rating = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{aspects}->{$aspect};
				my $aspect_ctr = $aspect_ct{$aspect};
				my $pack = $rating . "::" . $aspect;
				$worksheet->write($row_c_ctr + $codes_row_start, ($col_start+$aspect_ctr), $pack);
#				$worksheet->write($row_c_ctr + $codes_row_start, ($col_start+$aspect_ctr+1), $aspect);
			}
			$row_c_ctr++;
		}
	}
#	say "[cat:$cat][taskid:$taskid] iname[$iname] wrote [$iname_row_ctr] rows of data to *critical aspects stats* sheet";
	}
	
	return $taskid;
}
sub write_dispersion_clustering {
	my ($cat,$taskid,$option,$worksheet,$center_format,$heading_format1,$heading_format2,$shade_format,$trace) = @_;
	my $me = "WRITE-DISP-CLSTR-TABLES";
	$me = $me . "][Option:$option][taskid:$taskid][cat:$cat";
	
	my $headspace = 4;
	my $row_headspace = 3;
	
	my $blank_col_width = 3;
	my $code_rank_col = 0;
	my $code_rank_col_width = 7;
	my $code_words_col = 2;
	my $code_words_col_width = 8;
	my $code_title_col = 1;
	my $code_col_width = 40;
	my $code_subtree_words_col = 3;
	#my $code_words_col_width = 8;
	my $code_total_words_col = 4;
	#my $code_words_col_width = 8;
	my $code_iname_ct_col = 6;
	my $code_iname_ct_col_width = 6;
	my $code_code_ctr_col = 7;
	my $blob_summary_col = 8;
	my $blob_summary_col_width = 10;
	my $mean_summary_col = 9;
	my $cluster_cell_col_width = 4;

	my $blank_col = $code_title_col + 9;
	my $start_jump_col = 8;
	my $start_row_iname_clusters = 146;

	if(!defined $stats_base_disp) {
		die "[$me] stats_base_disp data variable is not loaded...check file load! at line[".__LINE__."]\n";
	}
	if(!exists $stats_base_disp->{by_iname}) {
		die "[$me] stats base dispersion hash has a bad structure at line[".__LINE__."]\n";
	}

	my %place_ctr = ();
	my %top_row_done = ();
	my $ct = 1;
	foreach my $iname (keys %{ $run_status->{active_6_done_codes_iname_disp} }) {
		$place_ctr{$iname} = $ct;
#		$top_row_done{$iname} = 0;
		$ct++;
	}
	foreach my $iname_index (keys %{ $run_status->{active_xls_iname_rank_order} }) {
		my $iname = $run_status->{active_xls_iname_rank_order}->{$iname_index};
		$place_ctr{$iname} = $iname_index;
		$top_row_done{$iname} = 0;
	}
	$ct = scalar(keys %place_ctr);
	say "[$me] active iname ct[".scalar(keys %place_ctr)."]" if $trace;
	
	## make header rows
	my $row_start = $headspace;
	my $col_inc = $code_title_col;
	$worksheet->write($row_start+2, $col_inc, "Main Code", $heading_format1);
#	$worksheet->write($row_start+2, $col_inc+1, "Level 2 SubCode", $heading_format1);
#	$worksheet->write($row_start+2, $col_inc+2, "Level 3+ SubCode", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc-1), "Ranking", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Base", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+1), "Word", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+1), "Counts", $heading_format1);
	$worksheet->write($row_start, ($col_inc+2), "Subtree", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+2), "Word", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+2), "Counts", $heading_format1);
	$worksheet->write($row_start, ($col_inc+3), "Total", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+3), "Word", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+3), "Counts", $heading_format1);
	## spkr counts cols
	$worksheet->write($row_start, ($col_inc+5), "Base", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+5), "SPKR", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+5), "Count", $heading_format1);
	$worksheet->write($row_start, ($col_inc+6), "Base", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+6), "Code", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+6), "Counter", $heading_format1);
	## nested cols
	$worksheet->write($row_start+1, ($col_inc+7), "Summary", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+7), "Dispersion", $heading_format1);
	$worksheet->write($row_start, ($col_inc+8), "Summary", $heading_format1);
	$worksheet->write($row_start+1, ($col_inc+8), "Mean", $heading_format1);
	$worksheet->write($row_start+2, ($col_inc+8), "Dispersion", $heading_format1);
	## tbase cols
#	$worksheet->write($row_start+2, ($col_inc+5), "Counts", $heading_format1);
#	$worksheet->write($row_start+1, ($col_inc+5), "TBase", $heading_format1);
#	$worksheet->write($row_start+2, ($col_inc+6), "Words", $heading_format1);
#	$worksheet->write($row_start+1, ($col_inc+6), "TBase", $heading_format1);
	## total cols
#	$worksheet->write($row_start+2, ($col_inc+9), "Counts", $heading_format1);
#	$worksheet->write($row_start+1, ($col_inc+9), "Total", $heading_format1);
#	$worksheet->write($row_start+2, ($col_inc+10), "Words", $heading_format1);
#	$worksheet->write($row_start+1, ($col_inc+10), "Total", $heading_format1);

	my $start_main_sum_row = $row_start + $row_headspace;
	my $end_main_sum_row = 145;
	my $col_add = 1;
	$col_inc = $col_inc + $col_add + $start_jump_col;
	$worksheet->write($row_start-1, ($col_inc+1), "Dispersion", $heading_format1);
	$worksheet->write($row_start, ($col_inc+2), "(Narrow:Medium:Wide)", $heading_format1);
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Codes", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-1, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-2, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	## adjust for $col_add starting at 1 and not 0
	$col_inc--;
	$worksheet->write($row_start-1, ($col_inc+1), "Dispersion", $heading_format1);
	$worksheet->write($row_start, ($col_inc+1), "Means", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+1, ($ct+$col_inc), "Codes", $heading_format1);
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		if($option) {
			my $ckey = $ct+$col_inc;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-1, $ckey, $sumform, $center_format );
			$worksheet->write($row_start-2, $ckey, "Sum", $heading_format1);
		}
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;

		$col_inc++;
	
	my $spacing = scalar(keys %place_ctr);

	if($option) {
		## make sheet title
#		$worksheet->write(0, 0, "Nested Codes - Summary Stats by Speaker - 1 unit == 1 sentence", $heading_format2);
	} else {
		## make sheet title
		$worksheet->write(0, 0, "Prime Codes - Dispersion Summary Stats by Speaker and Code Clustering - 1 unit == 1 sentence", $heading_format2);
	}
	
	$worksheet->set_column($code_rank_col, $code_rank_col, $code_rank_col_width);
	$worksheet->set_column($code_words_col, $code_words_col, $code_words_col_width);
	$worksheet->set_column($code_title_col, $code_title_col, $code_col_width);
	$worksheet->set_column($blob_summary_col, $blob_summary_col, $blob_summary_col_width);
#	$worksheet->set_column($code_l3_title_col, $code_l3_title_col, $code_l3_col_width);
	$worksheet->set_column($code_iname_ct_col, $code_iname_ct_col, $code_iname_ct_col_width);
#	$worksheet->set_column($code_wd_mean_col, $code_wd_mean_col, $code_wd_mean_col_width);
#	$worksheet->set_column($code_tbase_lines_col, $code_tbase_lines_col, $code_iname_ct_col_width);
	$worksheet->set_column($blank_col, $blank_col, $blank_col_width);

	my $start_col = $blank_col; ## increment cols after the blank col value
	my $padding = 1;

	if($option) {
		if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes} })) {
			say "[$me] nested codehref error...nested code list is not valid!";
			die "\tdying to fix at[".__LINE__."]\n";
		}
		my $nested_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes};
		say "[$me] nested codes loaded...size[".scalar(keys %$nested_codehref)."]" if $trace;
			
		if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_base_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_base_codes} })) {
			say "[$me] base codehref error...base code list is not valid!";
			die "\tdying to fix at[".__LINE__."]\n";
		}
		my $base_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_base_codes};
		say "[$me] base codes loaded...size[".scalar(keys %$base_codehref)."]" if $trace;

		my $rows = 0;
		my $row_ctr = $row_start + $row_headspace;
		if(scalar(keys %$base_codehref)) {
			my $low_limit = 1;
			if(exists $post_text_config->{prime_code_count_low_limit} and $post_text_config->{prime_code_count_low_limit}) {
				$low_limit = $post_text_config->{prime_code_count_low_limit};
			}
			my $_sorter = {};
			my $p_sorter = {};
			foreach my $code (keys %$base_codehref) {
				my $total = 0;
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count}) {
					$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count}) {
					$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count};
				}
				$p_sorter->{$code} = $total;
			}
			foreach my $code (keys %$nested_codehref) {
				my $total = 0;
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count}) {
					$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count}) {
					$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count};
				}
				$_sorter->{$code} = $total;
			}
			my $code_ctr = 1;
			my $c_ctr = 0;
			foreach my $code (sort { $p_sorter->{$b} <=> $p_sorter->{$a} } keys %$p_sorter) {
			}
		}
	} else {
		if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} })) {
			say "[$me] prime codehref error...prime code list is not valid!";
			die "\tdying to fix at[".__LINE__."]\n";
		}
		my $prime_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes};
		say "[$me] prime codes loaded...size[".scalar(keys %$prime_codehref)."]" if $trace;
		
		my $rows = 0;
		my $row_ctr = $row_start + $row_headspace;
		if(scalar(keys %$prime_codehref)) {
			my $low_limit = 1;
			if(exists $post_text_config->{prime_code_count_low_limit} and $post_text_config->{prime_code_count_low_limit}) {
				$low_limit = $post_text_config->{prime_code_count_low_limit};
			}
			my $c_ctr = 0;
			my $_sorter = {};
			foreach my $code (keys %$prime_codehref) {
				my $total = 0;
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count}) {
					$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count}) {
					$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count};
				}
#				my $total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{prime_code_stats}->{$code}->{lines}->{total}->{count};
				## check for valid 'total', skip if empty
				if(!$total) { 
					say "  [$me] setprime sorter hash...code[$code] code has NO total[".$total."]";
					next;
				}
				$_sorter->{$code} = $total;
				#say "  [$me] setprime sorter hash...code[$code] total[".$total."]";
			}
			my $ckey = 2;
			my $col_alpha = $col_converter{$ckey};
			my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
			$worksheet->write_formula( $row_start-1, $ckey, $sumform, $center_format );
			my $start_cluster = 0;
			#$worksheet->write($row_start-1, 4, $big_word_total, $heading_format1);
			say "[$me] prime sorter hash...size[".scalar(keys %$_sorter)."]" if $trace;
			foreach my $code (sort { $_sorter->{$b} <=> $_sorter->{$a} } keys %$_sorter) {
				my $allcount = $_sorter->{$code};
				if($low_limit > $allcount) {
					say " [$me] prime code loader, PER_code_stats, code[$code] code size too small[".$allcount."]";
					next;
				}
				my $text_code = $data_coding->{runlinks}->{code_form_mapping}->{$code};
				$worksheet->write($row_ctr, $code_title_col, $text_code);
#				$worksheet->write($row_ctr, $code_title_col, $code);
				my $allwords = 0;
				my $basewords = 0;
				my $subtreewords = 0;
				my $allinames = 0;
				my $allmean = 0;
				my $word_sum = 0;
				$worksheet->write($row_ctr, $code_rank_col, $allcount, $center_format);
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{tbase}) {
					$allwords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{tbase}->{count};
					$basewords = $allwords;
					$c_ctr++;
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{subtree}) {
					$subtreewords = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{subtree}->{count};
					$allwords = $allwords + $subtreewords;
				}
				$worksheet->write($row_ctr, $code_words_col, $basewords, $center_format);
				$worksheet->write($row_ctr, $code_subtree_words_col, $subtreewords, $center_format);
				$worksheet->write($row_ctr, $code_total_words_col, $allwords, $center_format);

				my $sum_narrow = 0;
				my $sum_narrow_sums = 0;
				my $sum_medium = 0;
				my $sum_wide = 0;
				my $sum_total_sums = 0;
				my $sum_total_counts = 0;

				foreach my $iname (keys %place_ctr) {
					if(!exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}) {
						next;
					}
					my $ct = $place_ctr{$iname};
					my $max_ct = scalar(keys %place_ctr);
					my $disp_blob_col = $start_col + $ct;
					my $narrow_mean_col = $start_col + $spacing + $ct;
					if(!$start_cluster) {
						$start_cluster = $start_col + $spacing + $max_ct + ($padding * 2);
					}
					
					my $narrow = 0;
					my $medium = 0;
					my $wide = 0;
					my $mean = 0;
					my $narrow_mean = 0;
					my $central_weight = 1;
					my $disp_out = "--:--:--";

					if(exists $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}) {
						if(exists $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}) {
							$narrow = $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{count};
						}
						if(exists $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{medium}) {
							$medium = $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{medium}->{count};
						}
						if(exists $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{wide}) {
							$wide = $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{wide}->{count};
						}
						if(exists $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}) {
							$sum_narrow_sums = $sum_narrow_sums + $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{sum};
						}
						$disp_out = $narrow . ":" . $medium . ":" . $wide;
						if($narrow or $medium or $wide) {
							$allinames++;
						}

						if(exists $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}) {
							$narrow_mean = $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean_narrow};
							if(exists $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean}) {
								$narrow_mean = $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean};
							}
							if(exists $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{count}) {
								$sum_total_counts = $sum_total_counts + $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{count};
								$sum_total_sums = $sum_total_sums + $stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{sum};
							}
						}

					}
					$sum_narrow = $sum_narrow + $narrow;
					$sum_medium = $sum_medium + $medium;
					$sum_wide = $sum_wide + $wide;
					
					$worksheet->write($row_ctr, $disp_blob_col, $disp_out, $center_format);

					## give 2 digits to the right
					if($narrow_mean=~/([\d]+)(\.[\d]+)/) {
						my $digits = $2 * 1000;
						my $first = $1;
						my $second = '000';
						if($digits=~/([\d]+)\.([\d]*)/) {
							$second = $1;
							if($second < 10) {
								$second = "00" . $second;
							}
							if($second < 100) {
								$second = "0" . $second;
							}
						}
						$narrow_mean = $first . "." . $second;
					}
#					if($narrow_mean) {
						$worksheet->write($row_ctr, $narrow_mean_col, $narrow_mean);
#					}

			  #	$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{group_num}->{sentence_grp_size} = $sent_ct_size;
#    dispersion:
 #     base:
  #      stats:
   #       AE designer interest:
    #        narrow:
     #         count: 0
      #        sum: 0
       #     total:
        #      count: 0
        #      mean_narrow: 0
        #      sum: 0
        #  EE:
        #    mass:
        #      hits:
        #        base: 236
        #        zeros: 127
        #      links:
        #        base: 235
        #        zeros: 106
        #      modus:
        #        hit_zeros: 1.53813559322034
        #        link_zeros: 1.45106382978723
        #    medium:
        #      count: 10
        #    narrow:
        #      count: 328
        #      mean: 1.02134146341463
        #      sum: 335
        #    total:
        #      count: 341
        #      mean: 1.99120234604106
        #      mean_narrow: 1.02134146341463
        #      sum: 679
        #    wide:
        #      count: 3
				}
				my $left_cell_loc_col = $start_cluster;
				foreach my $iname (keys %place_ctr) {
					my $r_spacer = 137;
					my $r_offset = -6;
					my $row_ct = $place_ctr{$iname};
					my $top_cluster_row = $start_row_iname_clusters + $r_spacer * ($row_ct - 1);
					my $cluster_row_ct = $row_ctr + $start_row_iname_clusters + $r_spacer * ($row_ct - 1) + $r_offset;
					if(exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}) {
						if(!$top_row_done{$iname}) {
							for (my $c=1; $c<101; $c++) {
								my $cell_loc_col = $start_cluster + $c;
								$worksheet->write($top_cluster_row, $cell_loc_col, $c, $heading_format1);
							}
							$top_row_done{$iname} = 1;
						}
						$worksheet->write($cluster_row_ct, $code_title_col, $text_code);
						$worksheet->write($cluster_row_ct, $left_cell_loc_col, $iname, $center_format);

						if(exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}) {
							if(exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}) {
								foreach my $index (sort{ $a <=> $b } keys %{ $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp} }) {
									my $value = $stats_base_disp->{all_inames}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$index}->{count};
									my $cell_loc_col = $start_cluster + $index;
									$worksheet->write($cluster_row_ct, $cell_loc_col, $value, $center_format);
								}
							}
						}
					}
				}
		
				if(exists $stats_base_disp->{all_inames}->{clustering}->{by_code}) {
					if(exists $stats_base_disp->{all_inames}->{clustering}->{by_code}->{$code}) {
						if(exists $stats_base_disp->{all_inames}->{clustering}->{by_code}->{$code}->{by_word_grp}) {
							foreach my $index (sort{ $a <=> $b } keys %{ $stats_base_disp->{all_inames}->{clustering}->{by_code}->{$code}->{by_word_grp} }) {
								my $value = $stats_base_disp->{all_inames}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$index}->{count};
								my $cell_loc_col = $start_cluster + $index;
								$worksheet->write($row_ctr, $cell_loc_col, $value, $center_format);

							}
						}
					}
				}

				my $sum_disp_out = $sum_narrow . ":" . $sum_medium . ":" . $sum_wide;
				$worksheet->write($row_ctr, $blob_summary_col, $sum_disp_out, $center_format);
				my $mean = 0;
				if($sum_total_counts) {
					$mean = $sum_total_sums / $sum_total_counts;
				}
				$worksheet->write($row_ctr, $mean_summary_col, $mean, $center_format);

				$worksheet->write($row_ctr, $code_code_ctr_col, $c_ctr, $center_format);
#				$worksheet->write($row_ctr, $code_cumm_percent_col, $percent, $center_format);
				$worksheet->write($row_ctr, $code_iname_ct_col, $allinames, $center_format);
#				
#				my $sumform = "=SUM(" . $col_alpha . $start_main_sum_row . ":" . $col_alpha . $end_main_sum_row . ")";
#				$worksheet->write_formula( $end_main_sum_row, $s, $sumform, $center_format );
				
				$row_ctr++;
			}
			my $top_row = $row_start + $row_headspace - 1;

			for (my $c=1; $c<101; $c++) {
				my $cell_loc_col = $start_cluster + $c;
				$worksheet->write($top_row, $cell_loc_col, $c, $heading_format1);
				$worksheet->set_column($cell_loc_col, $cell_loc_col, $cluster_cell_col_width);
			}
		}
		return 1;
	}


	return $taskid;
}

sub write_sent_clustering {
	my ($cat,$taskid,$iname,$worksheet,$href,$heading_format1,$heading_format2,$shade_format,$trace) = @_;

	
	$worksheet->write(0, 1, "Code Name", $heading_format1);
	$worksheet->set_column(0, 0, 4);
	$worksheet->set_column(1, 1, 40);
	$worksheet->write(0, 3, "Sentences - Numbered 1-to-N", $heading_format2);
	for (my $s=1; $s<500; $s++) {
		my $col = $s + 2;
		$worksheet->write(1, $col, $s, $heading_format1);
		$worksheet->set_column($col, $col, 5);
	}
	my $rows = 0;
	if(exists $href->{$iname}->{re_codes}->{clustering}->{by_sentence_index}) {
#		my $sent_list = $data_coding->{$iname}->{re_codes}->{sentences};
		my $limit_shading = scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sentences} });
		my $row_ctr = 2;
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{clustering}->{by_sentence_index} }) {
			$worksheet->write($row_ctr, 1, $code);
			$worksheet->write($row_ctr, 0, ($row_ctr - 1));
			my $col_ctr = 3;
			foreach my $sindex (keys %{ $href->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list} }) {
				my $count = $href->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sindex}->{count};
				$worksheet->write($row_ctr, $sindex+3, $count);
				$col_ctr++;
			}
			$worksheet->write($row_ctr, $limit_shading+3, '',$shade_format);
			$row_ctr++;
			$rows++;
		}
	}
	say "[cat:$cat][taskid:$taskid] iname[$iname] wrote [$rows] rows of codes to *sentence_clustering_stats* sheet";

	return $taskid;
}
sub write_topic_clustering {
	my ($cat,$taskid,$iname,$worksheet,$href,$heading_format1,$heading_format2,$shade_format,$trace) = @_;

	
	$worksheet->write(0, 1, "Code Name", $heading_format1);
	$worksheet->write(1, 1, "(Topic List Below)", );
	$worksheet->set_column(0, 0, 4);
	$worksheet->set_column(1, 1, 40);
	$worksheet->write(0, 3, "Topics - Numbered 1-to-N", $heading_format2);
	for (my $s=1; $s<50; $s++) {
		my $col = $s + 2;
		$worksheet->write(1, $col, $s, $heading_format1);
		$worksheet->set_column($col, $col, 5);
	}
	my $rows = 0;
	if(exists $href->{$iname}->{re_codes}->{clustering}->{by_topic}) {
#		my $sent_list = $data_coding->{$iname}->{re_codes}->{sentences};
		my $limit_shading = scalar(keys %{ $data_coding->{$iname}->{codes}->{topics} });
		my $row_ctr = 2;
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{clustering}->{by_topic} }) {
			$worksheet->write($row_ctr, 1, $code);
			$worksheet->write($row_ctr, 0, ($row_ctr - 1));
			my $col_ctr = 3;
			foreach my $sindex (keys %{ $href->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list} }) {
				my $count = $href->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$sindex}->{count};
				$worksheet->write($row_ctr, $sindex+3, $count);
				$col_ctr++;
			}
			$worksheet->write($row_ctr, $limit_shading+3, '',$shade_format);
			$row_ctr++;
			$rows++;
		}
	}
	say "[cat:$cat][taskid:$taskid] iname[$iname] wrote [$rows] rows of codes to *sentence_clustering_stats* sheet";

	my $topics_row_start = $rows + 4;
	my $topic_ctr = 1;
	my $row_t_ctr = 0;
	$worksheet->write($topics_row_start, 1, "Topic Name", $heading_format1);
	foreach my $topic (keys %{ $data_coding->{$iname}->{codes}->{topics} }) {
		my $limit_shading = scalar(keys %{ $data_coding->{$iname}->{codes}->{topics} });
		$worksheet->write($row_t_ctr + $topics_row_start, 1, $topic);
		$worksheet->write($row_t_ctr + $topics_row_start, 0, $topic_ctr);
		$row_t_ctr++;
		$topic_ctr++;
	}

	return $taskid;
}
sub write_nested_updown {
	my ($cat,$taskid,$worksheet,$href,$heading_format1,$heading_format2,$center_format,$shade_format,$trace) = @_;

	my %place_ctr = ();
	my %nested = ();
	my %nested_iname = ();
	my %nested_ranker = ();
	my $ct = 1;
	my $row_ctr = 0;
	foreach my $iname (keys %$href) {
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown} }) {
			my $found = 0;
			foreach my $code2 (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code} }) {
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_second_in_first} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_second_in_first}) {
					$nested{$code}{$code2} = 1;
					$nested_iname{$code} = $iname;
					$found = 1;
				}
			}
			if($found) {
				my $size = scalar(keys %{ $nested{$code} });
				$nested_ranker{$code} = $size;
				$row_ctr++;
			}
		}
		$place_ctr{$iname} = $ct;
		$ct++;
	}

	my $main_code_row = 1;
	my $nested_start_row = 3;
	my $nested_info_row = 4;
	my $start_col = 1;
	$worksheet->write($main_code_row, 0, "Main Code", $heading_format1);
	$worksheet->write($nested_start_row, 0, "Nested Codes", $heading_format2);
	$worksheet->write($nested_info_row, 0, "(Fully Nested)", $heading_format2);
	$worksheet->write($nested_info_row+2, 0, "(- Overlaps", $heading_format2);
	$worksheet->write($nested_info_row+3, 0, "listed below)", $heading_format2);
	$worksheet->set_column(0, 0, 12);
	$worksheet->set_column(1, 1, 6);

	my $n_col_ctr = $start_col + 1;
	foreach my $code (sort {$nested_ranker{$b} <=> $nested_ranker{$a}} keys %nested_ranker) {
#			$nested_ranker{$code} = $size;
#	foreach my $code (keys %nested) {
		$worksheet->write($main_code_row,$n_col_ctr, $code);
		$worksheet->set_column($n_col_ctr, $n_col_ctr, 25);
		my $iname = $nested_iname{$code};
		$worksheet->write($main_code_row+1,$n_col_ctr, $iname, $center_format);
		my $subnested = $nested{$code};
#		my $col_ctr = 2;
		my $row_ctr = 0;
		foreach my $code2 (keys %$subnested) {
			$worksheet->write($nested_start_row+$row_ctr, $n_col_ctr, $code2);
			$row_ctr++;
		}
		$n_col_ctr++;
	}

	my $o_main_code_row = 50;
	my $o_nested_start_row = 52;
	my $o_nested_info_row = 53;
	$worksheet->write($o_main_code_row, 0, "Main Code", $heading_format1);
	$worksheet->write($o_nested_start_row, 0, "Overlapping Codes", $heading_format2);
	$worksheet->write($o_nested_info_row, 0, "(Overlap:Code)", $heading_format2);

	my %o_place_ctr = ();
	my %o_nested = ();
	my %o_nested_ranked = ();
	my %o_nested_iname = ();
	my %o_nested_ranker = ();
	my $o_ct = 1;
	my $o_row_ctr = 0;
	foreach my $iname (keys %$href) {
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown} }) {
			my $found = 0;
			foreach my $code2 (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code} }) {
				#if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_second_in_first} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_second_in_first}) {
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap}) {
					$o_nested{$code}{$code2} = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap};
					$o_nested_iname{$code} = $iname;
					$o_nested_ranked{$code}{ $o_nested{$code}{$code2} }{$code2} = $iname;
					$found = 1;
				}
			}
			if($found) {
				my $size = scalar(keys %{ $o_nested{$code} });
				$o_nested_ranker{$code} = $size;
				$o_row_ctr++;
			}
		}
		$o_place_ctr{$iname} = $o_ct;
		$o_ct++;
	}
	my $o_col_ctr = $start_col + 1;
	foreach my $code (sort {$o_nested_ranker{$b} <=> $o_nested_ranker{$a}} keys %o_nested_ranker) {
#	foreach my $code (keys %nested) {
		$worksheet->write($o_main_code_row,$o_col_ctr, $code);
#		$worksheet->set_column($o_col_ctr, $o_col_ctr, 25);
		my $iname = $o_nested_iname{$code};
		$worksheet->write($o_main_code_row+1,$o_col_ctr, $iname, $center_format);
		my $subnested = $o_nested{$code};
		my $row_ctr = 0;
		foreach my $rank (sort {$b <=> $a} keys %{ $o_nested_ranked{$code} }) {
			my $subnested2 = $o_nested_ranked{$code}{$rank};
			#$o_nested_ranked{$code}{ $o_nested{$code}{$code2} }{$code2} = $iname;
			foreach my $code2 (keys %$subnested2) {
#				my $val = $subnested->{$code2} * 10;
				my $val = $rank * 10;
				$val = $val . "%::" . $code2;
				$worksheet->write($o_nested_start_row+$row_ctr, $o_col_ctr, $val);
				$row_ctr++;
			}
		}
		$o_col_ctr++;
	}

	return $taskid;
}	
sub write_linkage_updown_ranked {
	my ($cat,$taskid,$worksheet,$href,$heading_format1,$heading_format2,$center_format,$shade_format,$trace) = @_;

	## make sheet title
	$worksheet->write(0, 0, "Code Linkage Dispersion (Distance) by Speaker   --  1 unit == 1 sentence", $heading_format2);
	$worksheet->write(1, 0, "Strong Linkage", $heading_format2);
	$worksheet->write(1, 16, "Weak Linkage", $heading_format2);
	$worksheet->write(1, 8, "Possible Opposing Linkage", $heading_format2);

	my $low_threshold_caring = 25;
	my $low_threshold_mean = 1;
	my $strong_link_threshold = 75;
	my $weak_link_threshold = 11;
	my %place_ctr = ();
	my %ranked = ();
	my %count_ranker = ();
	my $ct = 1;
	my $row_ctr = 0;
	foreach my $iname (keys %$href) {
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown} }) {
			my $found = 0;
			my $big_count = 0;
			foreach my $code2 (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code} }) {
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{total}->{count} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{total}->{count}) {
					my $count = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{total}->{count};
					$big_count = $big_count + $count;
					my $mean = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{total}->{mean};
					if($mean=~/([\d]+)(\.[\d]+)/) {
						my $digits = $2 * 100;
						my $first = $1;
						my $second = '00';
						if($digits=~/([\d]+)\.([\d]*)/) {
							$second = $1;
							if($second < 10) {
								$second = "0" . $second;
							}
						}
						$mean = $first . "." . $second;
					}
					$ranked{$code}{$count}{$code2}{iname} = $iname;
					$ranked{$code}{$count}{$code2}{mean} = $mean;
					$ranked{$code}{$count}{$code2}{narrow_mean} = 0;
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{narrow}->{mean}) {
						my $nmean = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{narrow}->{mean};
						## give 2 digits to the right
						if($nmean=~/([\d]+)(\.[\d]+)/) {
							my $digits = $2 * 100;
							my $first = $1;
							my $second = '00';
							if($digits=~/([\d]+)\.([\d]*)/) {
								$second = $1;
								if($second < 10) {
									$second = "0" . $second;
								}
							}
							$nmean = $first . "." . $second;
						}
						$ranked{$code}{$count}{$code2}{narrow_mean} = $nmean;
					}
					#my $n_ct = 0;
					my $ratio = 0;
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{narrow}->{count} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{narrow}->{count}) {
						my $n_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{narrow}->{count};
						my $m_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{medium}->{count};
						my $w_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{wide}->{count};
						if(!$m_ct) { $m_ct = 0; }
						if(!$w_ct) { $w_ct = 0; }
						if($n_ct) {
							$ratio = (100 * $n_ct) / ($n_ct + $m_ct + $w_ct);
							if($ratio=~/([\d]+)(\.[\d]+)/) {
								$ratio = $1;
								my $digits = $2 * 10;
								if($digits > 5) {
									$ratio++;
								}
							}
						}
					}
					$ranked{$code}{$count}{$code2}{narrow_ratio} = $ratio;
					$found = 1;
				}
			}
			if($found) {
				$count_ranker{$code} = $big_count;
				$row_ctr++;
			}
		}
		$place_ctr{$iname} = $ct;
		$ct++;
	}

	my $start_col = 3;

	## make header rows
	my $row_start = 2;
	for (my $c=0; $c<3; $c++) {
		my $this_col = $c * 8;
		$worksheet->write($row_start, $this_col+2, "Code Name", $heading_format1);
		$worksheet->write($row_start, $this_col+1, "Rank", $heading_format1);
		$worksheet->write($row_start, $this_col+3, "Linkage To Code", $heading_format1);
		$worksheet->write($row_start, $this_col+4, "Speaker", $heading_format2);
		$worksheet->write($row_start, $this_col+5, "Mean Dispersion (Distance)", $heading_format2);
		$worksheet->write($row_start+1, $this_col+5, "Across All", $heading_format2);
		$worksheet->write($row_start+1, $this_col+6, "Narrow Dispersion", $heading_format2);
		$worksheet->write($row_start+1, $this_col+7, "% Narrow", $heading_format2);
		$worksheet->set_column($this_col, $this_col, 4);
		$worksheet->set_column($this_col+1, $this_col+1, 5);
		$worksheet->set_column($this_col+2, $this_col+2, 40);
		$worksheet->set_column($this_col+3, $this_col+3, 40);
		$worksheet->set_column($this_col+5, $this_col+5, 12);
		$worksheet->set_column($this_col+6, $this_col+6, 16);
		$worksheet->set_column($this_col+7, $this_col+7, 10);
	}

	my $rows = 0;
	my %code_ct = ();
	my $ctr = 1;
	my $r_row_ctr = $row_start + 3;
	my %cat_row_ctr = ('1'=> $r_row_ctr,'2'=> $r_row_ctr,'3'=> $r_row_ctr);
	foreach my $code (sort {$count_ranker{$b} <=> $count_ranker{$a}} keys %count_ranker) {
		my $subnested = $ranked{$code};
		$code_ct{$code} = $ctr;
		foreach my $icount (sort {$b <=> $a} keys %{ $ranked{$code} }) {
			if($icount < $low_threshold_caring) {
				next;
			}

			foreach my $code2 (keys %{ $subnested->{$icount} }) {
				if($ranked{$code}{$icount}{$code2}{narrow_mean} < $low_threshold_mean) {
					next;
				}
				my $cat_col_start = 16;
				my $cat = 3;
				my $ratio = $ranked{$code}{$icount}{$code2}{narrow_ratio};
				if($ratio < $weak_link_threshold) {
					$cat = 2;
					$cat_col_start = 8;
				} elsif($ratio > $strong_link_threshold) {
					$cat = 1;
					$cat_col_start = 0;
				}
				my $_row_ctr = $cat_row_ctr{$cat};
				$worksheet->write($_row_ctr, $cat_col_start, $ctr);
				$worksheet->write($_row_ctr, $cat_col_start+1, $icount,$center_format);
				$worksheet->write($_row_ctr, $cat_col_start+2, $code);
				$worksheet->write($_row_ctr, $cat_col_start+3, $code2);
				$worksheet->write($_row_ctr, $cat_col_start+4, $ranked{$code}{$icount}{$code2}{iname},$center_format);
				$worksheet->write($_row_ctr, $cat_col_start+5, $ranked{$code}{$icount}{$code2}{mean});
				$worksheet->write($_row_ctr, $cat_col_start+6, $ranked{$code}{$icount}{$code2}{narrow_mean});
				$worksheet->write($_row_ctr, $cat_col_start+7, $ratio . "%",$center_format);
				$cat_row_ctr{$cat}++;
			}
		}
		$ctr++;
	}

	return $taskid;

	foreach my $iname (keys %place_ctr) {
		if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}) {
			my $limit_shading = scalar(keys %{ $data_coding->{$iname}->{re_codes}->{topics} });
			my $row_ctr = 2;
			my $col_start = 3;
			my $ctr = 1;
			foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown} }) {
				$code_ct{$code} = $ctr;
				$worksheet->write($row_ctr, 0, $ctr);
				$worksheet->write($row_ctr, 1, $code);
				$worksheet->write($row_ctr, 2, 'Linkage');
				$worksheet->write($row_ctr+1, 0, $ctr);
				$worksheet->write($row_ctr+1, 2, 'Nesting');
				$worksheet->write( 1, $col_start+$ctr, $ctr, $heading_format1);
				$ctr++;
				$row_ctr = $row_ctr + 3;
			}
			$row_ctr = 2;
			#$row_ctr = 2;
			foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown} }) {
				foreach my $code2 (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code} }) {

					if(!exists $code_ct{$code2}) {
						say "[cat:$cat][taskid:$taskid][write_linkage_updown] Warning! Missing code [$code] column ";
						next;
					}
					my $n_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{narrow}->{count};
					if(!$n_ct) { $n_ct = 0; }
					my $m_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{medium}->{count};
					if(!$m_ct) { $m_ct = 0; }
					my $w_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{wide}->{count};
					if(!$w_ct) { $w_ct = 0; }
					my $best_match = 'N: ' . $n_ct;
					if($w_ct > $m_ct and $w_ct > $n_ct) {
						$best_match = 'W: ' . $w_ct;
					} elsif($m_ct > $n_ct) {
						$best_match = 'M: ' . $m_ct;
					}

					my $col_ctr = $code_ct{$code2};
					$worksheet->write($row_ctr, $col_start+$col_ctr, $best_match);

					my $nesting = '';
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap}) {
						$nesting = 'Overlap: ' . $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap};
					}
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_first_in_second} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_first_in_second}) {
						$nesting = 'Nested OVER';
					}
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_second_in_first} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_second_in_first}) {
						$nesting = 'Nested IN';
					}
					$worksheet->write($row_ctr+1, $col_start+$col_ctr, $nesting);

				}
				$row_ctr = $row_ctr + 3;
			}
		}
	}

	return $taskid;
}
sub write_dispersion_2x {
	my ($cat,$taskid,$worksheet,$href,$heading_format1,$heading_format2,$center_format,$shade_format,$trace) = @_;
	my $me = "WRITE-2X-DISP";
	$me = $me . "][taskid:$taskid][cat:$cat";
	print "= [$my_shortform_server_type][$me] write 2x dispersion\n" if $trace;
	my $trace_multi = 0;

	my $low_threshold_caring = 25;
	my %place_ctr = ();
	my $ct = 1;
	foreach my $iname (keys %$href) {
		$place_ctr{$iname} = $ct;
		$ct++;
	}
	
	## make sheet title
	$worksheet->write(0, 0, "2x Code Linkage Summary Stats by Speaker  --  1 unit == 1 sentence", $heading_format2);
	$worksheet->write(0, 3, "(Merged Code Frequency > " . $low_threshold_caring . " units)", $heading_format2);

	## make header rows
	my $row_start = 1;
	$worksheet->write($row_start+2, 0, "Code1-n-Code2 Merge", $heading_format1);
	$worksheet->write($row_start+1, 1, "% N", $heading_format1);
	$worksheet->write($row_start+2, 1, "Ratio", $heading_format1);
	$worksheet->write($row_start+2, 2, "Rank", $heading_format1);

	my $col_inc = 2;
	$worksheet->write($row_start, ($col_inc+1), "Unit Freq", $heading_format2);
	$worksheet->write($row_start+1, ($col_inc+1), "Count", $heading_format1);
#	$col_inc = 1;
	my $col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start, ($col_inc+1), "Char Weight", $heading_format2);
	$worksheet->write($row_start+1, ($col_inc+1), "Count", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), 12);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$col_inc++;
	$worksheet->set_column($col_inc, $col_inc, 4);
	$worksheet->write($row_start, ($col_inc+1), "Dispersion - Narrow", $heading_format2);
	$worksheet->write($row_start+1, ($col_inc+1), "Mean", $heading_format1);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;
	$worksheet->write($row_start, ($col_inc+1), "Dispersion - Narrow:Medium:Wide", $heading_format2);
	$worksheet->write($row_start+1, ($col_inc+1), "Counts", $heading_format2);
	$col_add = 0;
	foreach my $iname (keys %place_ctr) {
		my $ct = $place_ctr{$iname};
		$worksheet->write($row_start+2, ($ct+$col_inc), $iname, $heading_format1);
		$worksheet->set_column(($ct+$col_inc), ($ct+$col_inc), 15);
		$col_add++;
	}
	$col_inc = $col_inc + $col_add;

	$worksheet->set_column(0, 0, 60);
	$worksheet->set_column(1, 1, 5);
	$worksheet->set_column(1, 1, 5);

	my $low_ratio = 2;
	my %code_tcount = ();
	my %code_all_count = ();
	my %count_ranker = ();
	my %ranked = ();
	my %multi_ranker = ();
	my %src_containers = ();
	my %code_cont_src_map = ();
	my %code_cont_src_map2 = ();
	my %code_cont_map = ();
	my %container_ct = ();
	my $src_ct = 1;
	my %src_ctrs = ();
	my $cont_overlap = 0;
	foreach my $iname (keys %$href) {
#		if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}) {
		print "[$my_shortform_server_type][$me] iname[$iname] 2x disp code ct[".scalar(keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x} })."]\n" if $trace;
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x} }) {
			my $found = 0;
			my $big_count = 0;
			foreach my $code2 (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code} }) {
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{count} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{count}) {
					my $count = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{count};
					$big_count = $big_count + $count;
					my $mean = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{mean};

					if($mean=~/([\d]+)(\.[\d]+)/) {
						my $digits = $2 * 100;
						my $first = $1;
						my $second = '00';
						if($digits=~/([\d]+)\.([\d]*)/) {
							$second = $1;
							if($second < 10) {
								$second = "0" . $second;
							}
						}
						$mean = $first . "." . $second;
					}
					$ranked{$code}{$count}{$code2}{iname} = $iname;
					$ranked{$code}{$count}{$code2}{mean} = $mean;
					$ranked{$code}{$count}{$code2}{narrow_mean} = 0;
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{narrow}->{mean}) {
						my $nmean = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{narrow}->{mean};
						## give 2 digits to the right
						if($nmean=~/([\d]+)(\.[\d]+)/) {
							my $digits = $2 * 100;
							my $first = $1;
							my $second = '00';
							if($digits=~/([\d]+)\.([\d]*)/) {
								$second = $1;
								if($second < 10) {
									$second = "0" . $second;
								}
							}
							$nmean = $first . "." . $second;
						}
						$ranked{$code}{$count}{$code2}{narrow_mean} = $nmean;
					}
					my $ratio = 0;
					my $counts_text = "0:0:0";
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{narrow}->{count} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{narrow}->{count}) {
						my $n_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{narrow}->{count};
						my $m_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{medium}->{count};
						my $w_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{wide}->{count};
						if(!$m_ct) { $m_ct = 0; }
						if(!$w_ct) { $w_ct = 0; }
						$counts_text = $n_ct . ":" . $m_ct . ":" . $w_ct;
						
						if($n_ct) {
							$ratio = (100 * $n_ct) / ($n_ct + $m_ct + $w_ct);
							if($ratio=~/([\d]+)(\.[\d]+)/) {
								$ratio = $1;
								my $digits = $2 * 10;
								if($digits > 5) {
									$ratio++;
								}
							}
						}
					}
					say "[$me][$iname] multi-maker-2x [$code] count[$count] ratio![$ratio] BIG_count[$big_count] cts[$counts_text] sum[".$href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{sum}."] c2[$code2]" if $trace_multi;
					$ranked{$code}{$count}{$code2}{narrow_ratio} = $ratio;
					$ranked{$code}{$count}{$code2}{counts_text} = $counts_text;
					if($ratio) {
						$multi_ranker{$ratio}{$count}{$code}{$code2}{$iname} = 1;
						if($ratio < 100 and $ratio > ($low_ratio-1)) {
							if(!exists $src_ctrs{$ratio}) {
								$src_ctrs{$ratio} = 1;
							}
							$code_all_count{$ratio}{$code} = 1;
							$code_all_count{$ratio}{$code2} = 1;
							if(scalar(keys %{ $code_cont_src_map2{$ratio} })) {
								my $flag_ctr = 0;
								my $flag = 1;
								my $flag1 = 0;
								my $flag2 = 0;
								foreach my $_code (keys %{ $code_cont_src_map2{$ratio} }) {
									if($_code eq $code) {
										foreach my $_ctr (sort{$a <=> $b} keys %{ $code_cont_src_map2{$ratio}{$_code} }) {
											$flag1 = $_ctr;
											last;
										}
									}
									if($_code eq $code2) {
										foreach my $_ctr (sort{$a <=> $b} keys %{ $code_cont_src_map2{$ratio}{$_code} }) {
											$flag2 = $_ctr;
											last;
										}
									}
								}
								if(!$flag1 and !$flag2) {
									$flag = $src_ctrs{$ratio};
									$src_ctrs{$ratio}++;
								} elsif(!$flag1) {
									$flag = $flag2;
								} elsif(!$flag2) {
									$flag = $flag1;
								} elsif($flag2 > $flag1) {
									$flag = $flag1;
								} elsif($flag2 < $flag1) {
									$flag = $flag2;
								}
								$code=~s/[\s*]$//gi;
								$code2=~s/[\s*]$//gi;
								$code_cont_src_map2{$ratio}{$code}{$flag}{$code2} = 0;
								$code_cont_src_map2{$ratio}{$code2}{$flag}{$code} = 0;
								if(!exists $container_ct{$ratio}{$flag}) {
									$container_ct{$ratio}{$flag} = 0;
								}
								$code_cont_map{$flag}{$ratio}{$code}{$code2} = 0;
								$code_cont_map{$flag}{$ratio}{$code2}{$code} = 0;
								$container_ct{$ratio}{$flag} = $container_ct{$ratio}{$flag} + 1;
							} else {
							#	$src_ctrs{$ratio} = 1;
								my $_srcct = $src_ctrs{$ratio};

								$code_cont_src_map2{$ratio}{$code}{$_srcct}{$code2} = 0;
								$code_cont_src_map2{$ratio}{$code2}{$_srcct}{$code} = 0;
								$code_cont_map{$_srcct}{$ratio}{$code}{$code2} = 0;
								$code_cont_map{$_srcct}{$ratio}{$code2}{$code} = 0;
								say "\tNew [$ratio] map, starting new code1-2 set[$code][$code2] src_ct[$src_ct]";
								$container_ct{$ratio}{$_srcct} = 1;
								$src_ctrs{$ratio}++;
							}
						}
						if($ratio == 100) {
							if(!exists $src_ctrs{$ratio}) {
								$src_ctrs{$ratio} = 1;
							}
							$code_all_count{$ratio}{$code} = 1;
							$code_all_count{$ratio}{$code2} = 1;
							if(scalar(keys %code_cont_src_map2)) {
								my $flag_ctr = 0;
								my $flag = 1;
								my $flag1 = 0;
								my $flag2 = 0;
								foreach my $_code (keys %{ $code_cont_src_map2{$ratio} }) {
									if($_code eq $code) {
#									if($_code=~/^$code[\s*]$/) {
										foreach my $_ctr (sort{$a <=> $b} keys %{ $code_cont_src_map2{$ratio}{$_code} }) {
											$flag1 = $_ctr;
#											print "set flag1 code1[$code] flag1[$flag1] ";
											last;
										}
									}
									if($_code eq $code2) {
										foreach my $_ctr (sort{$a <=> $b} keys %{ $code_cont_src_map2{$ratio}{$_code} }) {
											$flag2 = $_ctr;
#											print "set flag2 code2[$code2] flag2[$flag2] code[$code]";
											last;
										}
									}
								}
#								if($flag1 or $flag2) { print "\n"; }
								if(!$flag1 and !$flag2) {
									$flag = $src_ctrs{$ratio};
									$src_ctrs{$ratio}++;
									if($src_ctrs{$ratio} > 100) {
										die "ctr is too big!";
									}
								} elsif(!$flag1) {
									$flag = $flag2;
								} elsif(!$flag2) {
									$flag = $flag1;
								} elsif($flag2 > $flag1) {
									####
									## flag1 is lower number container
									## add flag2 code AND code links to flag1 container
									####
									$flag = $flag1;
								} elsif($flag2 < $flag1) {
									####
									## flag2 is lower number container
									## add flag1 code AND code links to flag2 container
									####
									$flag = $flag2;
								}
								$code=~s/[\s*]$//gi;
								$code2=~s/[\s*]$//gi;
#								$tblock =~ s/##COM\d+##\s//gi;

								$code_cont_src_map2{100}{$code}{$flag}{$code2} = 0;
								$code_cont_src_map2{100}{$code2}{$flag}{$code} = 0;
								if(!exists $container_ct{100}{$flag}) {
									$container_ct{100}{$flag} = 0;
								}
								$code_cont_map{$flag}{100}{$code}{$code2} = 0;
								$code_cont_map{$flag}{100}{$code2}{$code} = 0;
								$container_ct{100}{$flag} = $container_ct{100}{$flag} + 1;
#								say "\tcode1-2 set[$code][$code2] flag[$flag] flag1-2[$flag1:$flag2] container ct[".scalar(keys %container_ct)."] [".$container_ct{$flag}."]";
							} else {
								$src_ctrs{$ratio} = 1;
								my $_srcct = $src_ctrs{$ratio};
								$code_cont_src_map2{100}{$code}{$_srcct}{$code2} = 0;
								$code_cont_src_map2{100}{$code2}{$_srcct}{$code} = 0;
								$code_cont_map{$_srcct}{100}{$code}{$code2} = 0;
								$code_cont_map{$_srcct}{100}{$code2}{$code} = 0;
								say "\tNO 100 map, starting new, code1-2 set[$code][$code2] src_ct[$src_ct]";
								$container_ct{100}{$_srcct} = 1;
								$src_ctrs{$ratio}++;
#								$src_ct++;
							}
						}
					}
					$found = 1;
				}
				say "[$me][$iname] multi-maker-2x [$code] ranked size on code[".scalar(keys %{ $ranked{$code} })."]" if $trace_multi;
			}
			if($found) {
				$count_ranker{$code} = $big_count;
#				$row_ctr++;
			}
		}
		my %code_cont_iname_map = ();
		foreach my $_code (keys %{ $code_cont_src_map2{100} }) {
			my $found_ctr = 0;
			my $found_size = 0;
			foreach my $_ctr (sort{$a <=> $b} keys %{ $code_cont_src_map2{100}{$_code} }) {
				my $size = keys %{ $code_cont_src_map2{100}{$_code}{$_ctr} };
				if($size > $found_size) {
					$found_ctr = $_ctr;
					$found_size = $size;
				}
			}
			$code_cont_iname_map{100}{$_code}{$found_ctr} = 0;
		}
		my %ctr_ctr = ();
		foreach my $_code (keys %code_cont_iname_map) {
			foreach my $src_ctr (keys %{ $code_cont_iname_map{$_code} }) {
				if(!exists $ctr_ctr{$src_ctr}) {
					$ctr_ctr{$src_ctr} = 0;
				}
				$ctr_ctr{$src_ctr}++;
			}
		}
		my %ctr_ranker = ();
		my $rctr = 1;
		foreach my $_ctr (sort{$ctr_ctr{$b} <=> $ctr_ctr{$a}} keys %ctr_ctr) {
			$ctr_ranker{$_ctr} = $rctr;
			$rctr++;
		}
		say "[$my_shortform_server_type][$me] [$iname] 2x Dispersion, iname ratio codes[".scalar(keys %code_cont_iname_map )."]  containers[".scalar(keys %ctr_ctr)."] ranker[".scalar(keys %ctr_ranker)."]" if $trace;
		foreach my $_code (keys %code_cont_iname_map) {
			foreach my $_ctr (keys %{ $code_cont_iname_map{$_code} }) {
				my $rctr = $ctr_ranker{$_ctr};
				$src_containers{$iname}{$rctr}{100}{$_code} = 1;;
			}
		}
		
		say "[$my_shortform_server_type][$me] [$iname] 2x Dispersion, 100% ratio cts[".scalar(keys %{ $multi_ranker{100} })."] 1st_codes[".scalar(keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x} })."]" if $trace;
	}

	my %cont_ctr = ();
	my %rev_cont_ctr = ();
	my %src_containers2 = ();
	for (my $i=100; $i>($low_ratio-1); $i--) {
		say "[$my_shortform_server_type][$me] 2x mapping ratio[$i], all codes[".scalar(keys %{ $code_all_count{$i} })."] container ct[".scalar(keys %{$container_ct{$i}})."] map containers[".scalar(keys %code_cont_map )."]" if $trace;
		my $r_ctr = 1;
		my $_cont = $container_ct{$i};
		foreach my $cct (sort{$_cont->{$b} <=> $_cont->{$a}} keys %$_cont) {
			$cont_ctr{$i}{$r_ctr} = $cct;
			$r_ctr++;
		}
		my $c_ct = 1; #scalar(keys %container_ct);
#		my $_rcont = $cont_ctr{$i}
		foreach my $cct (sort{$b <=> $a} keys %{ $cont_ctr{$i} }) {
			$rev_cont_ctr{$i}{$c_ct} = $cont_ctr{$i}{$cct};
			$c_ct++;
		}

		my $end_ctr = scalar(keys %$_cont);
		my $die_ctr = 0;
		
		## not sure why this has to be fixed....
		my $ccc_ctr = $cont_ctr{$i}{1};
		foreach my $_code (keys %{ $code_all_count{$i} }) {
			if(!exists $code_cont_map{$ccc_ctr}{$i}{$_code}) {
#			if(!exists $code_cont_map{$cc_ctr}{$i}{$_code}) {
#				say "   pre-missing i[$i] ccc_ctr[$ccc_ctr] hi-size[".scalar(keys %{ $code_cont_map{$ccc_ctr}{$i} })."] code[$_code]";
				if(exists $code_cont_src_map2{$i}{$_code}) {
#					say "  ?missing i[$i] to ccc_ctr[$ccc_ctr] code[$_code] sub ctrs[".scalar(keys %{ $code_cont_src_map2{$i}{$_code} })."]";
					foreach my $_ctr (keys %{ $code_cont_src_map2{$i}{$_code} }) {
#						say "    ?missing i[$i] to ccc_ctr[$ccc_ctr] from src map2 at[$_ctr] code[$_code] sub codes[".scalar(keys %{ $code_cont_src_map2{$i}{$_code}{$_ctr} })."]";
#					foreach my $_code2 (keys %{ $code_cont_src_map2{$i}{$_code}{$ccc_ctr} }) {
#						$code_cont_map{$ccc_ctr}{$i}{$_code}{$_code2} = 0;
#						$code_cont_map{$ccc_ctr}{$i}{$_code2}{$_code} = 0;
					}
				}
				$die_ctr++;
				if($die_ctr >500) { die; }
			}
		}
		for (my $cct=1; $cct<($end_ctr+1); $cct++) {
			my $cc_ctr = $cont_ctr{$i}{$cct};
			my $loop = $end_ctr - $cct;
			my $cct2 = 1;
			while($loop > 0) {
				if(!defined $rev_cont_ctr{$i}{$cct2} or !$rev_cont_ctr{$i}{$cct2}) {
					die "  missing c_ctr...i[$i] cct2[$cct2] cct[$cct] hi-size[".$_cont->{$cc_ctr}."] cc_ctr[$cc_ctr] end ctr[$end_ctr]";
				}
				my $c_ctr = $rev_cont_ctr{$i}{$cct2};
				foreach my $_code (keys %{ $code_all_count{$i} }) {
					## if code not in big hash, try to find it in small hash
					if(!exists $code_cont_map{$cc_ctr}{$i}{$_code}) {
						## if code is not code1, loop to find it
						if(!exists $code_cont_map{$c_ctr}{$i}{$_code}) {
							my $found = 0;
							foreach my $_code_lo (keys %{ $code_cont_map{$c_ctr}{$i} }) {
								my $found2 = 0;
								if(exists $code_cont_map{$c_ctr}{$i}{$_code_lo}{$_code}) {
									## found!
									$found2 = 1;
									$code_cont_map{$cc_ctr}{$i}{$_code}{$_code_lo} = 0;
									$code_cont_map{$cc_ctr}{$i}{$_code_lo}{$_code} = 0;
								}
								if($found2) {
									foreach my $_code2_lo (keys %{ $code_cont_map{$c_ctr}{$i}{$_code_lo} }) {
										$code_cont_map{$cc_ctr}{$i}{$_code_lo}{$_code2_lo} = 0;
										$code_cont_map{$cc_ctr}{$i}{$_code2_lo}{$_code_lo} = 0;
										delete $code_cont_map{$c_ctr}{$i}{$_code_lo}{$_code2_lo};
									}
									delete $code_cont_map{$c_ctr}{$i}{$_code_lo};
								}
							}
						} else {
							foreach my $_code2 (keys %{ $code_cont_map{$c_ctr}{$i}{$_code} }) {
								$code_cont_map{$cc_ctr}{$i}{$_code}{$_code2} = 0;
								$code_cont_map{$cc_ctr}{$i}{$_code2}{$_code} = 0;
								delete $code_cont_map{$c_ctr}{$i}{$_code}{$_code2};
							}
							delete $code_cont_map{$c_ctr}{$i}{$_code};
						}
					} else {
						## if exists in big hash, then check and clear small hash...
						## if code is not code1, loop to find it
						if(!exists $code_cont_map{$c_ctr}{$i}{$_code}) {
							my $found = 0;
							foreach my $_code_lo (keys %{ $code_cont_map{$c_ctr}{$i} }) {
								my $found2 = 0;
								if(exists $code_cont_map{$c_ctr}{$i}{$_code_lo}{$_code}) {
									## found!
									$found2 = 1;
									$code_cont_map{$cc_ctr}{$i}{$_code}{$_code_lo} = 0;
									$code_cont_map{$cc_ctr}{$i}{$_code_lo}{$_code} = 0;
								}
								if($found2) {
									foreach my $_code2_lo (keys %{ $code_cont_map{$c_ctr}{$i}{$_code_lo} }) {
										$code_cont_map{$cc_ctr}{$i}{$_code_lo}{$_code2_lo} = 0;
										$code_cont_map{$cc_ctr}{$i}{$_code2_lo}{$_code_lo} = 0;
										delete $code_cont_map{$c_ctr}{$i}{$_code_lo}{$_code2_lo};
									}
									delete $code_cont_map{$c_ctr}{$i}{$_code_lo};
								}
							}
						} else {
							foreach my $_code2 (keys %{ $code_cont_map{$c_ctr}{$i}{$_code} }) {
								$code_cont_map{$cc_ctr}{$i}{$_code}{$_code2} = 0;
								$code_cont_map{$cc_ctr}{$i}{$_code2}{$_code} = 0;
								delete $code_cont_map{$c_ctr}{$i}{$_code}{$_code2};
							}
							delete $code_cont_map{$c_ctr}{$i}{$_code};
						}
					}
				}
				$cct2++;
				$loop--;
			}
			if($loop < 1 and $cct == 1) {
				## hash large container...check for embedded codes
				foreach my $_code (keys %{ $code_cont_map{$cc_ctr}{$i} }) {
					foreach my $_code2 (keys %{ $code_cont_map{$cc_ctr}{$i}{$_code} }) {
						if(!exists $code_cont_map{$cc_ctr}{$i}{$_code2}) {
							$code_cont_map{$cc_ctr}{$i}{$_code2}{$_code} = 0;
							say "   missed i[$i] cct2[$cct2] cct[$cct] cc_ctr[$cc_ctr] hi-size[".scalar(keys %{ $code_cont_map{$cc_ctr}{$i} })."] added[$_code2]";
						}
					}
				}
				foreach my $_code (keys %{ $code_all_count{$i} }) {
					if(!exists $code_cont_map{$cc_ctr}{$i}{$_code}) {
#						$code_cont_map{$cc_ctr}{$i}{$_code2}{$_code} = 0;
						say "   missing i[$i] cct2[$cct2] cct[$cct] cc_ctr[$cc_ctr] hi-size[".scalar(keys %{ $code_cont_map{$cc_ctr}{$i} })."] code[$_code]";
						if(exists $code_cont_src_map2{$i}{$_code}) {
							foreach my $_cct (keys %{ $code_cont_src_map2{$i}{$_code} }) {
								say "     ?? missing i[$i] cct2[$cct2] cct[$cct] cc_ctr[$cc_ctr] in src map at[$_cct] code[$_code]";
								my $match = 0;
								foreach my $_code2 (keys %{ $code_cont_src_map2{$i}{$_code}{$_cct} }) {
									if(exists $code_cont_map{$cc_ctr}{$i}{$_code2}) {
										$match = 1;
										$code_cont_map{$cc_ctr}{$i}{$_code2}{$_code} = 0;
										$code_cont_map{$cc_ctr}{$i}{$_code}{$_code2} = 0;
										say "   missed i[$i] cct2[$cct2] cct[$cct] cc_ctr[$cc_ctr] hi-size[".scalar(keys %{ $code_cont_map{$cc_ctr}{$i} })."] added[$_code2]";
										delete $code_cont_map{$_cct}{$i}{$_code}{$_code2};
									}
								}
								if($match) {
									delete $code_cont_map{$_cct}{$i}{$_code};
								}
							}
						}
					}
				}
			}
		}
		say "[$my_shortform_server_type][$me] 2x mapping ratio[$i], cont_map ct[".scalar(keys %code_cont_map )."] end ctr[".$end_ctr."]" if $trace;
		foreach my $_ctr (keys %code_cont_map) {
			my $size = 0;
			my $size_na = 'NA';
			if(exists $code_cont_map{$_ctr}{$i}) {
				$size = scalar(keys %{ $code_cont_map{$_ctr}{$i} });
			}
			if($size) {
				say "  [cat:$cat][taskid:$taskid] 2x mapping ratio[$i], container ct-ing[$_ctr] code ct[".$size."] ";
			} else {
				say "  [cat:$cat][taskid:$taskid] 2x mapping ratio[$i], container ct-ing[$_ctr] code ct[".$size_na."] zero-size...deleting";
				delete	$code_cont_map{$_ctr}{$i};
			}
		}
	
		my %add_map = ();
#		foreach my $_code (keys %code_cont_src_map2) {
#			foreach my $_ctr (keys %{ $code_cont_src_map2{$_code} }) {
#				foreach my $_c (keys %{ $code_cont_src_map2{$_code}{$_ctr}{$i} }) {
#					$add_map{$_c}{$_ctr}{$i}{$_code} = 0;
#				}
#			}
#		}
		say "[cat:$cat][taskid:$taskid] 2x Dispersion ratio[$i], adds codes[".scalar(keys %add_map )."] map2[".scalar(keys %code_cont_src_map2 )."] all codes[".scalar(keys %{ $code_all_count{$i} })."]";
#		foreach my $_code (keys %add_map) {
#			foreach my $_ctr (keys %{ $add_map{$_code} }) {
#				foreach my $_c (keys %{ $add_map{$_code}{$_ctr}{$i} }) {
#					$code_cont_src_map2{$_code}{$_ctr}{$i}{$_c} = 0;
#				}
#			}
#		}
#		say "[cat:$cat][taskid:$taskid] 2x Dispersion ratio[$i], adds codes[".scalar(keys %add_map )."] map2[".scalar(keys %code_cont_src_map2 )."]";
		foreach my $_ctr (keys %code_cont_map) {
			if(exists $code_cont_map{$_ctr}{$i}) {
				foreach my $_code (keys %{ $code_cont_map{$_ctr}{$i} }) {
					foreach my $_code2 (keys %{ $code_cont_map{$_ctr}{$i}{$_code} }) {
						$code_cont_src_map{$_code}{$_ctr}{$i}{$_code2} = 0;
						$code_cont_src_map{$_code2}{$_ctr}{$i}{$_code} = 0;
					}
				}
			}
		}
#		foreach my $_code (keys %code_cont_src_map2) {
#			my $found_ctr = 0;
#			my $found_size = 0;
#			foreach my $_ctr (sort{$a <=> $b} keys %{ $code_cont_src_map2{$_code} }) {
#				my $size = scalar(keys %{ $code_cont_src_map2{$_code}{$_ctr}{$i} });
#				if($size > $found_size) {
#					$found_ctr = $_ctr;
#					$found_size = $size;
#				}
#			}
#			if(!$found_ctr) {
#				say "[cat:$cat][taskid:$taskid] 2x Dispersion containers, NO ctr[$found_ctr] for code[$_code] ctr:z[".scalar(keys %{ $code_cont_src_map2{$_code} })."] ";
#				next;
#			}
#			foreach my $_ctr (keys %{ $code_cont_src_map2{$_code} }) {
#				foreach my $_c (keys %{ $code_cont_src_map2{$_code}{$_ctr}{$i} }) {
#				$code_cont_src_map{$_code}{$found_ctr}{100}{$_c} = 0;
#					$code_cont_src_map{$_c}{$found_ctr}{$i}{$_code} = 0;
#				}
#			}
#		}
		my %ctr_ctr2 = ();
		foreach my $_code (keys %code_cont_src_map) {
			foreach my $src_ctr (keys %{ $code_cont_src_map{$_code} }) {
				if(!exists $ctr_ctr2{$src_ctr}) {
					$ctr_ctr2{$src_ctr} = 0;
				}
				$ctr_ctr2{$src_ctr}++;
			}
		}
		my %ctr_ranker2 = ();
		my $rctr2 = 1;
		foreach my $_ctr (sort{$ctr_ctr2{$a} <=> $ctr_ctr2{$b}} keys %ctr_ctr2) {
			$ctr_ranker2{$_ctr} = $rctr2;
			$rctr2++;
		}
		#$code_cont_src_map{$_code}{$_ctr}{$i}{$_code2} = 0;
		foreach my $_code (keys %code_cont_src_map) {
			foreach my $_ctr (keys %{ $code_cont_src_map{$_code} }) {
				my $rctr = $ctr_ranker2{$_ctr};
				foreach my $_c (keys %{ $code_cont_src_map{$_code}{$_ctr}{$i} }) {
					$src_containers2{$i}{$rctr}{$_code}{$_c} = 0;
				}
			}
		}
		say "[$my_shortform_server_type][$me] 2x mapping ratio[$i], ALL ratio code ct[".scalar(keys %code_cont_src_map )."]  container ratio ct[".scalar(keys %src_containers2)."] ranker[".scalar(keys %ctr_ranker2)."]" if $trace;
#		foreach my $_ctr (keys %src_containers2) {
#			say "[cat:$cat][taskid:$taskid] \t2x Dispersion containers ctr[$_ctr] size[".scalar(keys %{ $src_containers2{$_ctr}{100} })."] ";
#		}
	}
	
	my $spacing = scalar(keys %place_ctr);

	my $start_col = 2;
	my $padding = 1;
	my $row_ctr = $row_start + 3;

	say "[$my_shortform_server_type][$me] All 2x Dispersion, ratio (int %) ct[".scalar(keys %multi_ranker)."] speakers[$spacing] caring threshold[$low_threshold_caring]" if $trace;
	say "[$my_shortform_server_type][$me] All 2x Dispersion, 100%) containers[".scalar(keys %src_containers2)."] container overlap[$cont_overlap] " if $trace;
	
#	$multi_ranker{$ratio}{$icount}{$code}{$cod2}{$iname} = 1;
	foreach my $ratio (sort {$b <=> $a } keys %multi_ranker) {
		foreach my $icount (sort {$b <=> $a } keys %{ $multi_ranker{$ratio} }) {
			if($icount < $low_threshold_caring) {
				next;
			}
			foreach my $code (keys %{ $multi_ranker{$ratio}{$icount} }) {
				foreach my $code2 (keys %{ $multi_ranker{$ratio}{$icount}{$code} }) {
					foreach my $iname (keys %{ $multi_ranker{$ratio}{$icount}{$code}{$code2} }) {
						$worksheet->write($row_ctr, 0, $code . " <=> " . $code2);
						$worksheet->write($row_ctr, 1, $ratio, $center_format);
						$worksheet->write($row_ctr, 2, $icount, $center_format);
						my $ct = $place_ctr{$iname};
						my $count_col = $start_col + $ct;
						my $chars_col = $start_col + $spacing + $ct;
						my $mean_col = $start_col + $padding + $spacing + $spacing + $ct;
						my $counts_col = $start_col + $padding + $spacing + $spacing + $spacing + $ct;

						$worksheet->write($row_ctr, $count_col, $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{count}, $center_format);
						
#						my $chars1 = $data_coding->{$iname}->{re_codes}->{code_stats}->{$code}->{chars}->{total_count};
						my $chars1 = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count};
#						my $chars2 = $data_coding->{$iname}->{re_codes}->{code_stats}->{$code2}->{chars}->{total_count};
						my $chars2 = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code2}->{chars}->{total}->{count};
						$worksheet->write($row_ctr, $chars_col, $chars1 . ":" . $chars2, $center_format);

						my $nmean = $ranked{$code}{$icount}{$code2}{narrow_mean};
						$worksheet->write($row_ctr, $mean_col, $nmean);

						$worksheet->write($row_ctr, $counts_col, $ranked{$code}{$icount}{$code2}{counts_text}, $center_format);
						
					}
					$row_ctr++;
				}
			}
		}
	}
	
#	say "[cat:$cat][taskid:$taskid] iname[$iname] wrote [$rows] rows of codes to *per_code_stats* sheet";


	return \%src_containers2,\%code_cont_src_map;


	
	



	return $taskid;

	
	my $low_threshold_mean = 1;
#	my %place_ctr = ();
#	my %ranked = ();
#	my %count_ranker = ();
	my $start_row = 0;
#	my $ct = 1;
#	my $row_ctr = 0;
#	my $rows = 0;
	my %code_ct = ();
	my $ctr = 1;
	foreach my $iname (keys %$href) {
			#if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}) {
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x} }) {
			my $found = 0;
			my $big_count = 0;
			foreach my $code2 (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code} }) {
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{count} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total_count}) {
					my $count = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{count};
					$big_count = $big_count + $count;
#						   $statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$_code}->{stats}->{total}->{count} = $count2;

					my $mean = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{total}->{mean};
					if($mean=~/([\d]+)(\.[\d]+)/) {
						my $digits = $2 * 100;
						my $first = $1;
						my $second = '00';
						if($digits=~/([\d]+)\.([\d]*)/) {
							$second = $1;
							if($second < 10) {
								$second = "0" . $second;
							}
						}
						$mean = $first . "." . $second;
					}
					$ranked{$code}{$count}{$code2}{mean} = $mean;
					$ranked{$code}{$count}{$code2}{narrow_mean} = 0;
					if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{narrow}->{mean}) {
						my $nmean = $href->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$code2}->{stats}->{narrow}->{mean};
						## give 2 digits to the right
						if($nmean=~/([\d]+)(\.[\d]+)/) {
							my $digits = $2 * 100;
							my $first = $1;
							my $second = '00';
							if($digits=~/([\d]+)\.([\d]*)/) {
								$second = $1;
								if($second < 10) {
									$second = "0" . $second;
								}
							}
							$nmean = $first . "." . $second;
						}
						$ranked{$code}{$count}{$code2}{narrow_mean} = $nmean;
					}
					$found = 1;
				}
			}
			if($found) {
				$count_ranker{$code} = $big_count;
				$row_ctr++;
			}
		}
		$place_ctr{$iname} = $ct;
		$ct++;
	}
	
	return $taskid;
}
sub write_topic_aspect_clustering {
	my ($cat,$taskid,$iname,$worksheet,$href,$heading_format1,$heading_format2,$shade_format,$trace) = @_;

	
	$worksheet->write(0, 1, "Aspect Name", $heading_format1);
	$worksheet->write(1, 1, "(Topic List Below)", );
	$worksheet->set_column(0, 0, 4);
	$worksheet->set_column(1, 1, 40);
	$worksheet->write(0, 3, "Topics - Numbered 1-to-N", $heading_format2);
	for (my $s=1; $s<50; $s++) {
		my $col = $s + 2;
		$worksheet->write(1, $col, $s, $heading_format1);
		$worksheet->set_column($col, $col, 5);
	}
	my $rows = 0;
	if(exists $href->{$iname}->{re_aspects}->{clustering}->{by_topic}) {
#		my $sent_list = $data_coding->{$iname}->{re_codes}->{sentences};
		my $limit_shading = scalar(keys %{ $data_coding->{$iname}->{codes}->{topics} });
		my $row_ctr = 2;
		foreach my $aspect (keys %{ $href->{$iname}->{re_aspects}->{clustering}->{by_topic} }) {
			$worksheet->write($row_ctr, 1, $aspect);
			$worksheet->write($row_ctr, 0, ($row_ctr - 1));
			my $col_ctr = 3;
			foreach my $tindex (keys %{ $href->{$iname}->{re_aspects}->{clustering}->{by_topic}->{$aspect}->{list} }) {
				my $count = $href->{$iname}->{re_aspects}->{clustering}->{by_topic}->{$aspect}->{list}->{$tindex}->{count};
				$worksheet->write($row_ctr, $tindex+3, $count);
				$col_ctr++;
			}
			$worksheet->write($row_ctr, $limit_shading+3, '',$shade_format);
			$row_ctr++;
			$rows++;
		}
	}
	say "[cat:$cat][taskid:$taskid] iname[$iname] wrote [$rows] rows of codes to *sentence_clustering_stats* sheet";

	my $topics_row_start = $rows + 4;
	my $topic_ctr = 1;
	my $row_t_ctr = 0;
	$worksheet->write($topics_row_start, 1, "Topic Name", $heading_format1);
	foreach my $topic (keys %{ $data_coding->{$iname}->{codes}->{topics} }) {
		my $limit_shading = scalar(keys %{ $data_coding->{$iname}->{codes}->{topics} });
		$worksheet->write($row_t_ctr + $topics_row_start, 1, $topic);
		$worksheet->write($row_t_ctr + $topics_row_start, 0, $topic_ctr);
		$row_t_ctr++;
		$topic_ctr++;
	}

	return $taskid;
}
sub write_aspect_linkage_updown {
	my ($cat,$taskid,$iname,$worksheet,$href,$heading_format1,$heading_format2,$shade_format,$trace) = @_;

	
	$worksheet->write(0, 1, "Aspect Name", $heading_format1);
	$worksheet->write(1, 1, "(Code List Below)", );
	$worksheet->set_column(0, 0, 4);
	$worksheet->set_column(1, 1, 40);
	$worksheet->write(0, 3, "Linked Code - Numbered 1-to-N", $heading_format2);

	my $rows = 0;
	my %code_ct = ();
	if(exists $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}) {
		my $limit_shading = scalar(keys %{ $data_coding->{$iname}->{re_codes}->{topics} });
		my $row_ctr = 2;
		my $col_start = 3;
		my $ctr = 1;
		foreach my $aspect (keys %{ $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown} }) {
			$worksheet->write($row_ctr, 0, $ctr);
			$worksheet->write($row_ctr, 1, $aspect);
			$worksheet->write($row_ctr, 2, 'Linkage');
			$worksheet->write($row_ctr+1, 0, $ctr);
			$worksheet->write($row_ctr+1, 2, 'Nesting');
#			$worksheet->write(1, $col_start+$ctr, $ctr, $heading_format1);
			$ctr++;
			$row_ctr = $row_ctr + 3;
		}
		$row_ctr = 2;
		foreach my $aspect (keys %{ $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown} }) {
			$ctr = 1;
			foreach my $code (keys %{ $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect} }) {

				$worksheet->write(1, $col_start+$ctr, $ctr, $heading_format1);
				$code_ct{$code} = $ctr;
#				if(!exists $code_ct{$code}) {
#					say "[cat:$cat][taskid:$taskid][write_linkage_updown] Warning! Missing code [$code] column ";
#					next;
#				}
				my $n_ct = $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{narrow}->{count};
				if(!$n_ct) { $n_ct = 0; }
				my $m_ct = $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{medium}->{count};
				if(!$m_ct) { $m_ct = 0; }
				my $w_ct = $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{wide}->{count};
				if(!$w_ct) { $w_ct = 0; }
				my $best_match = 'N: ' . $n_ct;
				if($w_ct > $m_ct and $w_ct > $n_ct) {
					$best_match = 'W: ' . $w_ct;
				} elsif($m_ct > $n_ct) {
					$best_match = 'M: ' . $m_ct;
				}

				my $col_ctr = $code_ct{$code};
				$worksheet->write($row_ctr, $col_start+$col_ctr, $best_match);

				my $nesting = '';
				if(exists $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_overlap} and $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_overlap}) {
					$nesting = 'Overlap: ' . $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_overlap};
				}
				if(exists $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_complete_nesting_first_in_second} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_complete_nesting_first_in_second}) {
					$nesting = 'Nested OVER';
				}
				if(exists $href->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_complete_nesting_second_in_first} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_complete_nesting_second_in_first}) {
					$nesting = 'Nested IN';
				}
				$worksheet->write($row_ctr+1, $col_start+$col_ctr, $nesting);
				$ctr++;
			}
			$row_ctr = $row_ctr + 3;
		}
		$rows = $row_ctr;
	}

	my $codes_row_start = $rows + 4;
	my $code_ctr = 1;
	my $row_c_ctr = 0;
	$worksheet->write($codes_row_start, 1, "Code Name", $heading_format1);
	foreach my $code (sort {$code_ct{$a} <=> $code_ct{$b}} keys %code_ct) {
		$worksheet->write($row_c_ctr + $codes_row_start, 1, $code);
		$worksheet->write($row_c_ctr + $codes_row_start, 0, $code_ct{$code});
		$row_c_ctr++;
	}

	return $taskid;
}
sub write_aspect_criticals { ## old version....
	my ($cat,$taskid,$iname,$worksheet,$href,$heading_format1,$center_format,$shade_format,$trace) = @_;

	## make header row
	my $header_row = 2;
	$worksheet->write($header_row, 1, "Aspect Name", $heading_format1);
	$worksheet->write($header_row, 3, "Dispersion", $heading_format1);
	$worksheet->write($header_row+1, 3, "Ctr", $heading_format1);
	$worksheet->write($header_row, 4, "Dispersion", $heading_format1);
	$worksheet->write($header_row+1, 4, "Best Match", $heading_format1);
	$worksheet->write($header_row, 5, "Narrow", $heading_format1);
	$worksheet->write($header_row, 8, "Medium", $heading_format1);
	$worksheet->write($header_row, 11, "Wide", $heading_format1);
	$worksheet->write($header_row+1, 5, "Count", $heading_format1);
	$worksheet->write($header_row+1, 8, "Count", $heading_format1);
	$worksheet->write($header_row+1, 11, "Count", $heading_format1);
	$worksheet->write($header_row+1, 6, "Sum", $heading_format1);
	$worksheet->write($header_row+1, 9, "Sum", $heading_format1);
	$worksheet->write($header_row+1, 12, "Sum", $heading_format1);
	$worksheet->write($header_row+1, 7, "Mean", $heading_format1);
	$worksheet->write($header_row+1, 10, "Mean", $heading_format1);
	$worksheet->write($header_row+1, 13, "Mean", $heading_format1);
	$worksheet->write($header_row, 14, "Characters", $heading_format1);
	$worksheet->write($header_row, 15, "Words", $heading_format1);
	$worksheet->write($header_row, 16, "atx Lines", $heading_format1);
	$worksheet->write($header_row+1, 14, "Count", $heading_format1);
	$worksheet->write($header_row+1, 15, "Count", $heading_format1);
	$worksheet->write($header_row+1, 16, "Count", $heading_format1);

	$worksheet->set_column(0, 0, 4);
	$worksheet->set_column(1, 1, 40);
	$worksheet->set_column(2, 2, 3);
	$worksheet->set_column(4, 4, 15);
	$worksheet->set_column(14, 16, 14);
#	$worksheet->set_column(14, 15, 14);
#	$worksheet->set_column(15, 16, 14);

	my $rows = 0;
	my $ctr = 1;
	my %aspect_ct = ();
	my %aspect_ranker = ();
	my %aspect_ranked = ();
	if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}) {
		foreach my $aspect (keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats} }) {
			$aspect_ranker{$aspect} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{lines}->{total}->{count};
		}
	}
	my $_rctr = 1;
	foreach my $asp (sort {$aspect_ranker{$b} <=> $aspect_ranker{$a}} keys %aspect_ranker) {
		##
		$aspect_ranked{$_rctr} = $asp;
		$_rctr++;
	}
#	my %aspect_ranker = ();
#	if(exists $href->{$iname}->{re_aspects}->{linkage}->{dispersion}) {
	my $_row_ctr = $header_row + 2;
	if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}) {
		my $row_ctr = $header_row + 2;
		foreach my $aspect_ctr (sort{$a <=> $b} keys %aspect_ranked) {
#		foreach my $aspect (keys %{ $href->{$iname}->{re_aspects}->{linkage}->{dispersion} }) {
			$_row_ctr = $header_row + 2 + $aspect_ctr;
			my $aspect = $aspect_ranked{$aspect_ctr};
			$worksheet->write($_row_ctr, 1, $aspect);
			$worksheet->write($_row_ctr, 3, $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{lines}->{total}->{count}, $center_format);
			$worksheet->write($_row_ctr, 4, $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{ratings}->{total}->{count}, $center_format);
			$worksheet->write($_row_ctr, 5, $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{words}->{total}->{count}, $center_format);
			my $mean = $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{ratings}->{total}->{count} / $data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{lines}->{total}->{count};
			$worksheet->write($_row_ctr, 6, $mean, $center_format);
#			$worksheet->write($row_ctr, 3, $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{total_count}, $center_format);
			$aspect_ct{$aspect} = $ctr;
			my $n_ct = $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{narrow}->{count};
			if(!$n_ct) { $n_ct = 0; }
			my $m_ct = $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{medium}->{count};
			if(!$m_ct) { $m_ct = 0; }
			my $w_ct = $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{wide}->{count};
			if(!$w_ct) { $w_ct = 0; }
			my $best_match = 'narrow';
			if($w_ct > $m_ct and $w_ct > $n_ct) {
				$best_match = 'wide';
			} elsif($m_ct > $n_ct) {
				$best_match = 'medium';
			}
#			$worksheet->write($row_ctr, 4, $best_match, $center_format);

#			$worksheet->write($row_ctr, 5, $n_ct);
#			$worksheet->write($row_ctr, 6, $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{narrow}->{sum});
			$worksheet->write($row_ctr, 7, $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{narrow}->{mean});

			$worksheet->write($row_ctr, 8, $m_ct);
			$worksheet->write($row_ctr, 9, $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{medium}->{sum});
			$worksheet->write($row_ctr, 10, $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{medium}->{mean});
			
			$worksheet->write($row_ctr, 11, $w_ct);
			$worksheet->write($row_ctr, 12, $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{wide}->{sum});
			$worksheet->write($row_ctr, 13, $href->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{stats}->{wide}->{mean});
			
			$worksheet->write($row_ctr, 14, $href->{$iname}->{re_aspects}->{clustering}->{code_stats}->{$aspect}->{chars}->{total_count});
#			$worksheet->write($row_ctr, 14, $data_postparse->{post_parse}->{$iname}->{re_codes}->{clustering}->{code_stats}->{$aspect}->{chars}->{total_count});
#			$worksheet->write($row_ctr, 15, $data_postparse->{post_parse}->{$iname}->{re_codes}->{clustering}->{code_stats}->{$aspect}->{words}->{total_count});
#			$worksheet->write($row_ctr, 16, $data_postparse->{post_parse}->{$iname}->{re_codes}->{clustering}->{code_stats}->{$aspect}->{lines}->{total_count});
			$ctr++;
			$row_ctr++;
		}
		$rows = $row_ctr;
	}

	my $codes_row_start = $rows + 3;
	my $row_c_ctr = 0;
	$worksheet->write($codes_row_start, 1, "Critical Text Segments ~~", $heading_format1);
	$worksheet->write($codes_row_start+1, 1, "Aspect", $heading_format1);
	$worksheet->write($codes_row_start+1, 3, "Rating", $heading_format1);
	$worksheet->write($codes_row_start+1, 4, "T-S Key", $heading_format1);
	$worksheet->write($codes_row_start+1, 5, "Text Segment", $heading_format1);

#	$statcodes->{$iname}->{re_aspects}->{ratings}->{critical}->{$aspect}->{by_rating}->{$rating}->{$tskey}->{text};
	$row_c_ctr = $row_c_ctr + 2;

	if(exists $href->{$iname}->{re_aspects}->{ratings}->{critical}) {
		foreach my $aspect (keys %{ $href->{$iname}->{re_aspects}->{ratings}->{critical} }) {
			foreach my $rating (sort {$b <=> $a} keys %{ $href->{$iname}->{re_aspects}->{ratings}->{critical}->{$aspect}->{by_rating} }) {
				foreach my $tskey (sort {$a cmp $b} keys %{ $href->{$iname}->{re_aspects}->{ratings}->{critical}->{$aspect}->{by_rating}->{$rating} }) {
					if(exists $href->{$iname}->{re_aspects}->{ratings}->{critical}->{$aspect}->{by_rating}->{$rating}->{$tskey}->{text} and $href->{$iname}->{re_aspects}->{ratings}->{critical}->{$aspect}->{by_rating}->{$rating}->{$tskey}->{text}) {
						my $aspect_ctr = $aspect_ct{$aspect};
						$worksheet->write($row_c_ctr + $codes_row_start, 0, $aspect_ctr, $center_format);
						$worksheet->write($row_c_ctr + $codes_row_start, 1, $aspect);
						$worksheet->write($row_c_ctr + $codes_row_start, 3, $rating, $center_format);
						$worksheet->write($row_c_ctr + $codes_row_start, 4, $tskey, $center_format);
						$worksheet->write($row_c_ctr + $codes_row_start, 5, $href->{$iname}->{re_aspects}->{ratings}->{critical}->{$aspect}->{by_rating}->{$rating}->{$tskey}->{text});
						$row_c_ctr++;
					}
				}
			}
		}
	}
	
	say "[cat:$cat][taskid:$taskid] iname[$iname] wrote [$rows] rows of codes to *critical aspects stats* sheet";

	return $taskid;
}
sub write_2x_code_groups {
	my ($cat,$taskid,$worksheet,$src_containers,$code_cont_src_map,$heading_format1,$heading_format2,$center_format,$shade_format,$trace) = @_;

	my $low_point = 2;
	my %totaler = ();
	my %sizes = ();
	for (my $i=100; $i>($low_point-1); $i--) {
		my $_cont = $src_containers->{$i};
		foreach my $_ctr (sort {$b <=> $a} keys %$_cont) {
			say "[cat:$cat][taskid:$taskid] 2x code groups, ratio[$i] containers ctr[$_ctr] size[".scalar(keys %{ $_cont->{$_ctr} })."] ";
			foreach my $code (keys %{ $_cont->{$_ctr} }) {
				my $size = scalar(keys %{ $_cont->{$_ctr}->{$code} });
				$totaler{$code}{$i} = $size * $i;
				$sizes{$i}{$code} = $size;
				if(!exists $totaler{$code}{101}) {
					$totaler{$code}{101} = 0;
				}
				$totaler{$code}{101} = $totaler{$code}{$i} + $totaler{$code}{101};
			}
		}
	}
	my %columns = ();
	foreach my $_i (keys %sizes) {
		my $_row = $sizes{$_i};
		if(!exists $columns{$_i}) {
			$columns{$_i} = 0;
		}
		foreach my $_code (keys %{ $sizes{$_i} }) {
			$columns{$_i} = $columns{$_i} + $sizes{$_i}{$_code};
		}
	}
	my $ctr = 1;
	my %t_ranker = ();
	foreach my $_code (keys %totaler) {
		my $_total = $totaler{$_code}{101};
		$t_ranker{$_code} = $_total;
	}
	foreach my $_code (sort {$t_ranker{$b} <=> $t_ranker{$a}} keys %t_ranker) {
		if(!exists $totaler{$_code}{111}) {
			$totaler{$_code}{111} = 0;
		}
		if(!exists $totaler{$_code}{121}) {
			$totaler{$_code}{121} = 0;
		}
		my $search_code = $_code;
		my $start_code = $_code;
		for (my $i=100; $i>55; $i--) {
			my $max = 0;
			if(exists $src_containers->{$i}->{1}->{$search_code}) {
				my $_totals = $totaler{$search_code};
				my $sub_cont = $src_containers->{$i}->{1}->{$search_code};
				my $max_code = $search_code;
				foreach my $_code2 (keys %{$sub_cont}) {
					if($_totals->{$i} > $max) {
						$max = $_totals->{$i};
						$max_code = $_code2;
					}
				}
				$search_code = $max_code;
			}
			$totaler{$_code}{111} = $totaler{$_code}{111} + $max;
		}
		my %summers = ($_code => 1);
		my $sum = 0;
		my $die_ct = 0;
		for (my $i=100; $i>95; $i--) {
			my @pusher = ();
			foreach my $_code_sum (keys %summers) {
				if($summers{$_code_sum}) {
					push @pusher, $_code_sum;
				}
			}
			while(scalar(@pusher)) {
				my $_code_sum = shift @pusher;
#				if(!$summers{$_code_sum}) {
#					next;
#				}
				if(exists $src_containers->{$i}->{1}->{$_code_sum}) {
#					my $_totals = $totaler{$_code_sum};
					my $sub_cont = $src_containers->{$i}->{1}->{$_code_sum};
					foreach my $_code2 (keys %{$sub_cont}) {
						$summers{$_code2} = 1;
						$sum++;
					}
					$summers{$_code_sum} = 0;
					$die_ct++;
					if($die_ct > 30000) { die "too much...[$sum] [$i]"; }
				}
			}
		}
		$totaler{$_code}{121} = $totaler{$_code}{121} + $sum;
	}

	my $row_start = 3;
	my $row = $row_start;
	my $cctr = 1;
	my $hctr = $cctr + 4;
	for (my $i=100; $i>($low_point-1); $i--) {
		$worksheet->write($row_start-2, $hctr, $i);
		$worksheet->write($row_start-1, $hctr, $columns{$i});
		$hctr++;
	}
	foreach my $_code (sort {$t_ranker{$b} <=> $t_ranker{$a}} keys %t_ranker) {
		my $_totals = $totaler{$_code};
		my $_sizes = $sizes{$_code};
		$worksheet->set_column($cctr, $cctr, 30);
		$worksheet->set_column($cctr+1, $cctr+1, 10);
		$worksheet->set_column($cctr+2, $cctr+2, 10);
		$worksheet->write($row, $cctr, $_code);
		$worksheet->write($row, $cctr+1, $t_ranker{$_code});
		$worksheet->write($row, $cctr+2, $_totals->{111});
		$worksheet->write($row, $cctr+3, $_totals->{121});
		$cctr = $cctr + 4;
		for (my $i=100; $i>($low_point-1); $i--) {
			my $s = '';
			if(exists $sizes{$i}{$_code}) {
				$s = $sizes{$i}{$_code};
			}
			$worksheet->write($row, $cctr, $s);
			$worksheet->set_column($cctr, $cctr, 6);
			$cctr++;
			$ctr = $cctr;
		}
		$row++;
		$cctr = 1;
	}

	$ctr++;
	for (my $i=100; $i>($low_point-1); $i--) {
		my $r_ctr = 1;
		my $_cont = $src_containers->{$i};
#					$src_containers2{$i}{$rctr}{$_code}{$_c} = 0;
		my $row_ctr = 1;
		my $indent = 2;
		if($i < 100) {
			$indent = 3;
		} 
		if($i < 99) {
			$indent = 4;
		}
		foreach my $_ctr (sort {$b <=> $a} keys %$_cont) {
			say "[cat:$cat][taskid:$taskid] 2x code groups, ratio[$i] containers ctr[$_ctr] size[".scalar(keys %{ $_cont->{$_ctr} })."] ";
			$worksheet->set_column($ctr, $ctr, 30);
			$worksheet->set_column($ctr+1, $ctr+1, 10);
			my %ranker = ();
			foreach my $code (keys %{ $_cont->{$_ctr} }) {
				my $size = scalar(keys %{ $_cont->{$_ctr}->{$code} });
#				$ranker{$size} = $code;
				$ranker{$code} = $size;
#			foreach my $code2 (keys %{ $src_containers->{$_ctr}->{100}->{$code} }) {
#				$worksheet->write($row_ctr, $ctr, $code2);
#			}
			}
			say "[cat:$cat][taskid:$taskid] 2x containers, ratio[$i] cont ctr[$_ctr] codes ranked[".scalar(keys %ranker)."]";
			foreach my $_code (sort{$ranker{$b} <=> $ranker{$a}} keys %ranker) {
				$worksheet->write($row_ctr, $ctr, $_code);
				$ctr++;
				$worksheet->write($row_ctr, $ctr, $ranker{$_code});
				if($i < 100) {
					$ctr++;
					my $_matt = "";
					if(exists $src_containers->{100}->{1}->{$_code}) {
						$_matt = "XX";
					}
					$worksheet->write($row_ctr, $ctr, $_matt);
					if($i < 99) {
						$ctr++;
						my $_mattt = "";
						if(exists $src_containers->{99}->{1}->{$_code}) {
							$_mattt = "X";
						}
						$worksheet->write($row_ctr, $ctr, $_mattt);
						$ctr--;
					}
					$ctr--;
				}
				$row_ctr++;
				$ctr--;
			}
			$ctr = $ctr + $indent;
		}
	}
	
	return $taskid;

}

sub calc_code_dist {
	my ($cat,$task_id,$trace) = @_;
	my $me = "CALC-CODE-DIST";
	$me = $me . "][taskid:$task_id][cat:$cat";
	print "= [$my_shortform_server_type][$me] = code distances calc\n" if $trace;

	if(!defined $data_postparse) {
		die "CODE FAIL! fix your mess.";
	}
	if(!defined $data_coding) {
		die "CODE FAIL! fix your mess.";
	}
	if(!defined $data_stats) {
		my $file = $dir . $yml_dir . $statsfile;
		say "[$me] Stats NOT loaded, reloading Stats file[$statsfile]...this may take a moment..." if $trace;
#		if(open(my $fh, '<', $file)) {
#			$data_stats = LoadFile($file);
#		} else {
#			die "\nERROR! cannot open [$file] [$!]";
#		}
	}
	if(!defined $data_stats_2x) {
		my $file = $dir . $yml_dir . $stats2xfile;
		say "[$me] Stats2x NOT loaded, reloading Stats2x file[$stats2xfile]...this may take a moment..." if $trace;
#		if(open(my $fh, '<', $file)) {
#			$data_stats_2x = LoadFile($file);
#		} else {
#			die "\nERROR! cannot open [$file] [$!]";
#		}
	}
	if(!defined $data_stats_linkage) {
		my $file = $dir . $yml_dir . $statslinkfile;
		say "[$me] StatsLinkage NOT loaded, reloading Stats Linkage file[$statslinkfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_stats_linkage = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}
	if(!defined $data_stats_updn) {
		my $file = $dir . $yml_dir . $statsupdnfile;
		say "[$me] StatsUpDn NOT loaded, reloading Stats updn file[$statsupdnfile]...this may take a moment..." if $trace;
#		if(open(my $fh, '<', $file)) {
#			$data_stats_updn = LoadFile($file);
#		} else {
#			die "\nERROR! cannot open [$file] [$!]";
#		}
	}
	if(!defined $data_clustering) {
		my $file = $dir . $yml_dir . $clusterfile;
		say "[$me] DataClustering NOT loaded, reloading data_clustering file[$clusterfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_clustering = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}
	if(!defined $data_stats_aspects) {
		my $file = $dir . $yml_dir . $statsaspectsfile;
		say "[$me] Stat Aspects NOT loaded, reloading data_stats_aspects file[$statsaspectsfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_stats_aspects = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}
	if(!defined $anal_coding) {
		my $file = $dir . $yml_dir . $v2nalyticsfile;
		say "[$me] Analytics V2 NOT loaded, reloading data_analytics file[$v2nalyticsfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$anal_coding = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}
	if(!defined $stats_base_disp) {
		my $file = $dir . $yml_dir . $stats_basefile;
		say "[$me] Base Stats V2 NOT loaded, reloading base stats file[$stats_basefile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$stats_base_disp = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}


#	my $ddir = $dir . $yml_dir;
#	&dump_coding_to_yml($data_coding,$ddir,$bakcodingfile,$trace);
	if(exists $run_status->{parse_is_new_for_coding} and $run_status->{parse_is_new_for_coding}) {
		if(!exists $run_status->{parts_are_new_for_coding} or !$run_status->{parts_are_new_for_coding}) {
			die "\t[$me] out of order execution of methods as line [".__LINE__."]\n";
		}
		if(!exists $run_status->{codes_are_new_for_coding} or !$run_status->{codes_are_new_for_coding}) {
			die "\t[$me] out of order execution of methods as line [".__LINE__."]\n";
		}
	}
	if(exists $run_status->{parts_are_new_for_coding} and $run_status->{parts_are_new_for_coding}) {
		if(!exists $run_status->{codes_are_new_for_coding} or !$run_status->{codes_are_new_for_coding}) {
			die "\t[$me] out of order execution of methods as line [".__LINE__."]\n";
		}
	}
	if(exists $run_status->{codes_are_new_for_coding} and $run_status->{codes_are_new_for_coding}) {
		my $rdir = $dir;
		## save old stats to a backup file
		if(defined $data_stats) {
			if(exists $run_status->{backup_stats_data} and $run_status->{backup_stats_data}) {
				my $bakfile = $statsfilenam . "_" . $dtg . ".yml";
				&dump_recovery_file_to_yml($data_stats,$rdir,$bakfile,$trace);
			}
		}
		if(defined $data_stats_2x) {
			if(exists $run_status->{backup_stats_data} and $run_status->{backup_stats_data}) {
				my $bakfile = $stats2xfilenam . "_" . $dtg . ".yml";
				&dump_recovery_file_to_yml($data_stats_2x,$rdir,$bakfile,$trace);
			}
		}
	}

	my $iname_ctr = 0;
	my $multi_success = 0;
	my $sum_success = 0;

	foreach my $iname (keys %{ $data_postparse->{aquad_meta_parse}->{name_codes} }) {
#		if(!exists $run_status->{active_parsing_iname_coding}->{$iname} or !$run_status->{active_parsing_iname_coding}->{$iname}) {
		if(!exists $run_status->{active_parsing_iname_dispersion_LOCALTOG}->{$iname} or !$run_status->{active_parsing_iname_dispersion_LOCALTOG}->{$iname}) {
#			if(!exists $run_status->{active_parsing_iname_dispersion}->{$iname} or !$run_status->{active_parsing_iname_dispersion}->{$iname}) {
				## skip...not re-coding this file data
				say "= [$my_shortform_server_type][$me]  skipping iname[$iname] - no change to prev existing data" if $trace;
				next;
			}
#		}
		say "\t[$me] iname[$iname] checking for re-codes......." if $trace;
		if(exists $data_coding->{$iname}->{re_codes}) {
			say "\t[$me] re_codes exist for iname[$iname] sent ct[".scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sentences} })."]" if $trace;
			my $sent_list = $data_coding->{$iname}->{re_codes}->{sentences};
			my $src_type = $data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_type};

			## make code list
			my $code_list = &make_code_list($sent_list,$iname,$task_id,$trace);
			say "[$my_shortform_server_type][$me] iname[$iname] code list size [".scalar(keys %$code_list)."]" if $trace;

			## check for multi src type...handle differently
			if($src_type=~/^multi/i) {
				## get the parse reference key
				## all file inames will be done at the same time...no reason to do otherwise...
				my $src_parse_key = $data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_parse_key};
				if(!$multi_success) {
					$multi_success = &set_code_dispersion_multi($cat,$task_id,$src_parse_key,$code_list,$trace);
					say "[$me] iname[$iname] completed code dispersion multi [".scalar(keys %$code_list)."]" if $trace;
				}
			} else {
				&set_code_dispersion($cat,$task_id,$sent_list,$code_list,$iname,$trace);
				say "[$me] iname[$iname] completed code dispersion [".scalar(keys %$code_list)."]" if $trace;
			}

			## make aspect list
#			my $aspect_list = &make_aspect_list($sent_list,$iname,$task_id,$trace);
#			say "[$me] iname[$iname] aspect list size [".scalar(keys %$aspect_list)."]" if $trace;

#			&set_aspect_dispersion($cat,$task_id,$sent_list,$aspect_list,$code_list,$iname,$trace);
#			say "[$me] iname[$iname] completed aspect dispersion [".scalar(keys %$aspect_list)."]" if $trace;

			$iname_ctr++;
#			say "= [$my_shortform_server_type][$task_id] code meshing complete for [".$iname."] ctr[$iname_ctr]" if $trace;
		}
	}
	if(!$sum_success) {
		$sum_success = &make_summary_dispersion_stats($cat,$task_id,$trace);
	}
	
	$run_status->{dispersion_calc_codes}->{iname_total_count} = scalar(keys %{ $data_stats->{by_iname} });
	$run_status->{dispersion_calc_codes}->{disp_calc_iname_ctr} = $iname_ctr;;
	

	## save results...hopefully good :)
	if(exists $codes_dirty->{dispersion} and $codes_dirty->{dispersion}) {
		if(!defined $data_coding) {
			die "CODE FAIL! fix your mess.";
		}
		if(exists $codes_dirty->{re_codes} and $codes_dirty->{re_codes}) {
			my $ddir = $dir . $yml_dir;
			## don't wipe out your data file, yet :)....
			&dump_coding_to_yml($data_coding,$ddir,$codingfile,$trace);
		}
		say "[$my_shortform_server_type][$me] completed analysis dispersion [".scalar(keys %{ $data_analysis->{by_iname} })."]" if $trace;

		if(exists $data_analysis->{by_iname} and scalar(keys %{ $data_analysis->{by_iname} })) {
			#my $a_yaml = &make_analytics_file($data_coding,$trace,0);
#			&dump_coding_to_yml($data_analysis,$ddir,$testanalyticsfile,$trace);

			my $ddir = $dir . $yml_dir;
#			&dump_coding_to_yml($data_stats,$ddir,$statsfile,$trace);

			&dump_coding_to_yml($data_analysis,$ddir,$v2nalyticsfile,$trace);

			&dump_coding_to_yml($data_stats_2x,$ddir,$stats2xfile,$trace);

			&dump_coding_to_yml($data_stats_linkage,$ddir,$statslinkfile,$trace);
			
			if(exists $data_stats_updn->{by_iname}) {
#				&dump_coding_to_yml($data_stats_updn,$ddir,$statsupdnfile,$trace);
			}
			if(exists $data_clustering->{by_iname}) {
				&dump_coding_to_yml($data_clustering,$ddir,$clusterfile,$trace);
			}
			
		}
		if(exists $codes_dirty->{base_dispersion} and $codes_dirty->{base_dispersion}) {
			my $ddir = $dir . $yml_dir;
			if(exists $anal_coding->{by_iname}) {
				&dump_coding_to_yml($anal_coding,$ddir,$v2nalyticsfile,$trace);
			}
			if(exists $stats_base_disp->{by_iname}) {
				&dump_coding_to_yml($stats_base_disp,$ddir,$stats_basefile,$trace);
			}
			$codes_dirty->{base_dispersion} = 0;
		}
		if(exists $codes_dirty->{aspect_dispersion} and $codes_dirty->{aspect_dispersion}) {
			my $ddir = $dir . $yml_dir;
			if(exists $data_stats_aspects->{by_iname}) {
				&dump_coding_to_yml($data_stats_aspects,$ddir,$statsaspectsfile,$trace);
			}
			$codes_dirty->{aspect_dispersion} = 0;
		}

		$run_status->{state_coding} = 3;
		$run_status->{state_coding_info} = 'code -n- aspect dispersion calculated';
		$run_status->{last_disp_dtg} = $dtg;

	}

	return $task_id;
}
sub calc_aspects {
	my ($cat,$taskid,$trace) = @_;
	my $me = "CALC-CODE-DIST";
	$me = $me . "][taskid:$taskid][cat:$cat";
	print "= [$my_shortform_server_type][$me] = code distances calc\n" if $trace;

	if(!defined $data_stats_aspects) {
		my $file = $dir . $yml_dir . $statsaspectsfile;
		say "[$me] Stat Aspects NOT loaded, reloading data_stats_aspects file[$statsaspectsfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_stats_aspects = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}
	if(!defined $stats_base_disp) {
		my $file = $dir . $yml_dir . $stats_basefile;
		say "[$me] Base Stats V2 NOT loaded, reloading base stats file[$stats_basefile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$stats_base_disp = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}

	my $iname_ctr = 0;
	foreach my $iname (keys %{ $data_postparse->{aquad_meta_parse}->{name_codes} }) {
#		if(!exists $run_status->{active_parsing_iname_coding}->{$iname} or !$run_status->{active_parsing_iname_coding}->{$iname}) {
		if(!exists $run_status->{active_parsing_iname_dispersion_LOCALTOG}->{$iname} or !$run_status->{active_parsing_iname_dispersion_LOCALTOG}->{$iname}) {
#			if(!exists $run_status->{active_parsing_iname_dispersion}->{$iname} or !$run_status->{active_parsing_iname_dispersion}->{$iname}) {
				## skip...not re-coding this file data
				say "= [$my_shortform_server_type][$me]  skipping iname[$iname] - no change to prev existing data" if $trace;
				next;
			}
#		}
		say "\t[$me] iname[$iname] checking for re-codes......." if $trace;
	
		if(exists $data_coding->{$iname}->{re_codes}) {
			say "\t[$me] re_codes exist for iname[$iname] sent ct[".scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sentences} })."]" if $trace;
			my $sent_list = $data_coding->{$iname}->{re_codes}->{sentences};
#			my $src_type = $data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_type};

			## make code list
			my $code_list = &make_code_list($sent_list,$iname,$taskid,$trace);
			say "[$my_shortform_server_type][$me] iname[$iname] code list size [".scalar(keys %$code_list)."]" if $trace;

			## make aspect list
			my $aspect_list = &make_aspect_list($sent_list,$iname,$taskid,$trace);
			say "[$me] iname[$iname] aspect list size [".scalar(keys %$aspect_list)."]" if $trace;

			&set_aspect_dispersion($cat,$taskid,$sent_list,$aspect_list,$code_list,$iname,$trace);
			say "[$me] iname[$iname] completed aspect dispersion [".scalar(keys %$aspect_list)."]" if $trace;

			$iname_ctr++;
		}
	}
	$run_status->{dispersion_calc_codes}->{iname_total_count} = scalar(keys %{ $data_stats_aspects->{by_iname} });
	$run_status->{dispersion_calc_codes}->{disp_calc_iname_ctr} = $iname_ctr;;

	## save results...hopefully good :)
	if(exists $codes_dirty->{dispersion} and $codes_dirty->{dispersion}) {
		if(!defined $stats_base_disp) {
			die "CODE FAIL! fix your mess.";
		}
		my $ddir = $dir . $yml_dir;
		if(exists $codes_dirty->{aspect_dispersion} and $codes_dirty->{aspect_dispersion}) {
			if(exists $data_stats_aspects->{by_iname}) {
				&dump_coding_to_yml($data_stats_aspects,$ddir,$statsaspectsfile,$trace);
			}
			$codes_dirty->{aspect_dispersion} = 0;
		}
		if(exists $codes_dirty->{base_dispersion} and $codes_dirty->{base_dispersion}) {
			if(exists $stats_base_disp->{by_iname}) {
				&dump_coding_to_yml($stats_base_disp,$ddir,$stats_basefile,$trace);
			}
			$codes_dirty->{base_dispersion} = 0;
		}
	}

#	if(exists $data_stats_aspects->{by_iname}) {
#		&dump_coding_to_yml($data_stats_aspects,$ddir,$statsaspectsfile,$trace);
#	}
	
	$run_status->{state_calc} = 2;
	$run_status->{state_calc_info} = 'aspect dispersion calculated';
	$run_status->{last_aspect_calc_dtg} = $dtg;

	return $taskid;
}

sub parse_txt_files {
	my ($cat,$task_id,$trace) = @_;
	my $me = 'PARSE-TXT';
	$me = $me . "][taskid:$task_id][cat:$cat";
	print "= [$my_shortform_server_type][$me] = parse files;\n" if $trace;

	my $file_count = 1;
	
	if(!defined $data_postparse) {
		my $file = $dir . $yml_dir . $postparsefile;
		say "[PARSING][taskid:$task_id] PostParse NOT loaded, reloading PostParse file[$parsingfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_postparse = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}
	if(defined $data_postparse and scalar(keys %$data_postparse)) {
		say "[$me] PostParse reloaded; key ct[".scalar(keys %{$data_postparse})."]" if $trace;
		foreach my $key (keys %{$data_postparse}) {
			say "\tTop key [$key] option ct[".scalar(keys %{$data_postparse->{$key}})."] " if $trace;
			if($key=~/^parse_meta$/i) {
				say "\t\t[$key] by_name ct[".scalar(keys %{$data_postparse->{aquad_meta_parse}})."] " if $trace;
			}
		}
	}

	if(scalar(keys %file_list_href)) {
		foreach my $ind (keys %{ $run_status->{active_parsing_files} }) {
			delete $run_status->{active_parsing_files}->{$ind};
			if(exists $run_status->{active_parsing_fkey_map}->{$ind}) {
				my $fkey = $run_status->{active_parsing_fkey_map}->{$ind};
				delete $run_status->{active_parsing_fkey_map}->{$ind};
				if(exists $run_status->{active_parsing_fkeys}->{$fkey}) {
					$run_status->{active_parsing_fkeys}->{$fkey} = 0;
				}
			}
		}
		if(!defined $new_data_postparse or !exists $new_data_postparse->{aquad_meta_parse}) {
			$new_data_postparse->{aquad_meta_parse} = $data_postparse->{aquad_meta_parse};
		}
		if(!defined $new_data_postparse or !exists $new_data_post_coding->{aquad_meta_coding}) {
			$new_data_post_coding->{aquad_meta_coding} = $data_post_coding->{aquad_meta_coding};
		}
		if(!defined $data_coding or !exists $data_coding->{runlinks}->{name_codes}) {
			$data_coding->{runlinks}->{name_codes} = {};
		}
	}
	my $inames = [];
	my $new_data_parsing = {};

	foreach my $findex (sort {$a <=> $b} keys %file_list_href) {
		my $file = $file_list_href{$findex};

		## set path, too
		my $filename = $file;
		$file = $dir . $file;
		
		my $rawtext = undef;

		if(open(my $fh, '<', $file)) {
			$rawtext = do { local $/; <$fh> };
		} else {
			print "ERROR! cannot open [$file]\n";
		}

		say "[$me] Begin parse of [$file] with [".length($rawtext)."] chars" if $runtime;

		my $fkey = "f".$findex;

		
		if($filename=~/-/) {
			## filename contains a hyphen that indicates multiple person responses within the file

			say "\tfile [$filename] is a multi-person text file, parse all respondents" if $trace;
			&parse_multi_file($task_id,$findex,$file,$filename,$rawtext,$new_data_parsing,$inames,$trace);
							#($task_id,$file_ct,$file,$filename,$rawtext,$ydata,$inames,$trace) = @_;
		} else {
			## filename contains a single person response
			say "\tfile [$filename] is a single-person text file, parse [$filename] respondent" if $trace;
			&parse_mono_file($task_id,$findex,$file,$filename,$rawtext,$new_data_parsing,$inames,$trace);

		}
		say "[$me] file[$filename] fkeys returned [".scalar(keys %$new_data_parsing)."]" if $runtime;

		$run_status->{active_1_last_parsed_files}->{$findex} = $filename;
		$run_status->{active_1_last_parsed_file_to_fkey_map}->{$findex} = $fkey;
		$run_status->{active_1_last_parsed_fkeys}->{$fkey} = 1;
		$run_status->{active_2_needs_tpliting_fkeys}->{$fkey} = 1;
		$file_count++;
	}
	$file_count--;

	## bring old existing data forward into new data_parse
	foreach my $fkey (keys %$data_parsing) {
		if(!exists $new_data_parsing->{$fkey}) {
			$new_data_parsing->{$fkey} = $data_parsing->{$fkey};
			if(exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}) {
				$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey} = $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey};
			}
		}
	}

	## get existing inames, from previous post_parse data and delete new names
	my %iname_sorter = ();
	foreach my $iname (keys %{ $data_postparse->{post_parse} }) {
		$iname_sorter{$iname} = 1;
		say "[taskid:$task_id} iname[$iname] in prev post parse" if $runtime;
	}
	for (my $i=0; $i<scalar(@$inames); $i++) {
		my $n = $inames->[$i];
		say "[taskid:$task_id} iname[$n] index ctr[$i] in new post parse...removing" if $runtime;
		if(exists $iname_sorter{$n}) {
			delete $iname_sorter{$n};
		}
	}
	## bring old existing post_parse data forward into new data_postparse
	say "[taskid:$task_id} inames retained from prev[".scalar(keys %iname_sorter)."] ... add these to NEW postparse data " if $runtime;
	foreach my $iname (keys %{ $data_postparse->{post_parse} }) {
		if(!exists $iname_sorter{$iname} or !$iname_sorter{$iname}) {
			next;
		}
		if(!exists $new_data_postparse->{post_parse}->{$iname}) {
			$new_data_postparse->{post_parse}->{$iname} = $data_postparse->{post_parse}->{$iname};
			say "[taskid:$task_id} added existing [$iname] PARSE data to NEW postparse data " if $runtime;
		}
#		if(!exists $new_data_post_coding->{post_coding}->{$iname}) {
#			$new_data_post_coding->{post_coding}->{$iname} = $data_post_coding->{post_coding}->{$iname};
#			say "[taskid:$task_id} added existing [$iname] CODING data to NEW postparse data " if $runtime;
#		}
	}
	
	say "\n[taskid:$task_id} Number of files parsed [$file_count]. Dumping to yaml" if $runtime;
	if($file_count) {
		my $ddir = $dir . $yml_dir;
		my $rdir = $dir;

		## save old parse to a backup file
		if(defined $data_parsing) {
			my $bakfile = $parsingfilenam . "_" . $dtg . ".yml";
			#&dump_coding_to_yml($data_parsing,$ddir,$bakfile,$trace);
			&dump_recovery_file_to_yml($data_parsing,$rdir,$bakfile,$trace);
		}
		if(defined $new_data_parsing and scalar(keys %$new_data_parsing)) {
			&dump_coding_to_yml($new_data_parsing,$ddir,$parsingfile,$trace);
		}
		## replace data in data parse with new stuff
		$data_parsing = undef;
		$data_parsing = $new_data_parsing;


		if(defined $data_postparse) {
			#postparsefile
			my $bakfile = $postparsefilenam . "_" . $dtg . ".yml";
			#&dump_coding_to_yml($data_postparse,$ddir,$bakfile,$trace);
			&dump_recovery_file_to_yml($data_postparse,$rdir,$bakfile,$trace);

		}
		if(defined $new_data_postparse and scalar(keys %$new_data_postparse)) {
			&dump_coding_to_yml($new_data_postparse,$ddir,$postparsefile,$trace);
		}

		if(!defined $data_analysis) {
			$data_analysis->{by_code} = {};
		}
		my $a_yaml = &make_analytics_file($data_coding,$trace,0);
		if(!defined $a_yaml) {
			die "CODE FAIL! fix your file building mess!";
		}
		&dump_coding_to_yml($a_yaml,$ddir,$testanalyticsfile,$trace);
		
		$run_status->{state_parse} = 1;
		$run_status->{state_parse_info} = 'texts parsed';
		$run_status->{last_parse_dtg} = $dtg;
		$run_status->{parsed_files}->{count} = $file_count;
		
	}
	
	return 1;
}
sub parse_multi_file {
	my ($task_id,$file_ct,$file,$filename,$rawtext,$ydata,$inames,$trace) = @_;

	my $name_generator = {};
	
	my $len = length($rawtext);
	say "[$task_id] parse_multi file [$file_ct|$filename] length chars[$len]" if $trace;
	
	my ($p1,$p2) = split '_',$filename;
	if($p1!~/-/) {
		die "bad file name [$file]\n";
	}
	my @p = split '-',$p1;
	my $p2end = $p2;
	if($p2 =~ /(.*)\.txt/i) {
		$p2end = $1;
	}
	say "[$task_id] name parts, p1[$p1] p2[$p2] p2end[$p2end] p0[".$p[0]."]" if $trace;
	my $fkey = "f".$file_ct;

	for (my $i=0; $i<scalar(@p); $i++) {
		my $f = $p[$i];
		$name_generator->{$f} = $p2;
		say "for file[$filename] make[$f] split-able in text";
		
		## swap (iname) value to +\iname\+ format
		## assume some dumass transcriber did not use a ptr such as (iname) or ((iname))
		$rawtext =~ s/\(($f)\)/+\\$1\\+/gi;

		my $cfound = 0;
		foreach my $iname (keys %{$new_data_postparse->{aquad_meta_parse}->{name_codes}}) {
			if($iname=~/^$f$/i) {
				$cfound = 1;
				last;
			}
		}
		if(!$cfound) {
			my $iname = uc $f;
			$new_data_postparse->{aquad_meta_parse}->{name_codes}->{$iname} = 1;
			$data_coding->{$iname}->{codes}->{topic_coding} = {};
		}

		my $found = 0;
		foreach my $iname (keys %{$new_data_postparse->{aquad_meta_parse}->{name_codes}}) {
			if($iname=~/^$f$/i) {
				$found = 1;
				last;
			}
		}
		my $iname = uc $f;
		push @$inames, $iname;
		if(!$found) {
			$new_data_postparse->{aquad_meta_parse}->{name_codes}->{$iname} = 1;

			$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{name_code} = $iname;
			if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{role}) {
				$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{role} = 'ee';
			}
			if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{gender}) {
				$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{gender} = 'M';
			}
			if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{age_category}) {
				$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{age_category} = '4';
			}
			if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{audio_rec}) {
				$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{audio_rec} = 'wav';
			}
			if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{audio_rec_time}) {
				$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{audio_rec_time} = '1:29';
			}
			if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{group_size}) {
				$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{group_size} = 4;
			}
			if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{start_time}) {
				$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{start_time} = '13:00';
			}
		}
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src} = $filename;
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_date} = $p2end;
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_type} = 'multi';
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_parse_key} = $fkey;
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{name_no_ext} = $f . "_" . $p2end;
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{root_name} = $f . "_" . $p2end;
#		my $name = $data_coding->{$topkey}->{profile}->{files}->{root_name};

	}
	$ydata->{$fkey}->{src} = $p1;
	$ydata->{$fkey}->{src_type} = 'multi';
	$ydata->{$fkey}->{peeps} = \@p;

	my ($prenewdata,$themes) = &extract_themes($rawtext,$trace);
	say "[$task_id] filect[$file_ct] data length - minus themes [".length($prenewdata)."] themes [".scalar(@$themes)."]  " if $trace;
	if(scalar(@$themes)) {
		$ydata->{$fkey}->{themes} = $themes;
	}

	my ($newdata,$comments) = &extract_setting_comments($prenewdata,$trace);
	say "[$task_id] filect[$file_ct] data length - comment markers [".length($newdata)."] comments[".scalar(keys %$comments)."]" if $trace;
	if(scalar(keys %$comments)) {
		$ydata->{$fkey}->{comments} = $comments;
	}

	my $new_data = &remove_extra_wspace($newdata,$trace);
	
	## make everything lowercase
	my $new_idata = lc $new_data;
	
	say "[$task_id] filect[$file_ct] fkey[$fkey] trimmed data length [".length($new_data)."]" if $trace;

#	my ($topics,$blocks) = &extract_topics($new_data,$trace);

	my $y = {};
	&extract_topics_to_yml($new_data,$y,$trace);
	if(scalar(keys %$y)) {
		$ydata->{$fkey}->{extract} = $y;
	}
	say "[$task_id] filect[$file_ct] fkey[$fkey] ydata size[".scalar(keys %$ydata)."]" if $trace;

	return 1;
}
sub parse_mono_file {
	my ($task_id,$file_ct,$file,$filename,$rawtext,$new_parsing,$inames,$trace) = @_;
	my $me = 'PARSE-MONO';
	$me = $me . "][taskid:$task_id";

	my $len = length($rawtext);
	say "[$me] parse_mono file [$file_ct|$filename] length chars[$len]" if $trace;

#	my ($p1,$p2) = split '_',$filename;
	my @fnparts = split '_',$filename;
	if(!scalar(@fnparts)) {
		die "[$me] cannot parse filename! [$filename] ... dying at [".__LINE__."]\n";
	}
	my $p1 = $fnparts[0];
	my $p2 = $fnparts[1];
	my $fkey = "f".$file_ct;
	$new_parsing->{$fkey}->{src} = $p1;
	$new_parsing->{$fkey}->{peep} = $p1;
	$new_parsing->{$fkey}->{iname} = uc $p1;
	my $fn = '';
	for (my $p=0; $p<scalar(@fnparts); $p++) {
		if($fnparts[$p]=~/([\.\-\da-zA-Z]+)\.txt$/i) {
			$new_parsing->{$fkey}->{filenam} = $fn . "_" . $1;
			last;
		}
		if($fn) {
			$fn = $fn . "_" . $fnparts[$p];
		} else {
			$fn = $fnparts[$p];
		}
	}
#	$filename=~/([\da-zA-Z]+)_([\d\.]+)\.txt$/i;
	#my ($p1,$p2) = split '_',$filename;
	say "[$task_id] name parts, p1[$p1] p2[$p2] filenam[$fn] date[$p2]" if $trace;

	$new_parsing->{$fkey}->{src_type} = 'mono';

	my ($prenewdata,$themes) = &extract_themes($rawtext,$trace);
	say "[$me] filect[$file_ct] data length - minus themes [".length($prenewdata)."] themes [".scalar(@$themes)."]  " if $trace;
	if(scalar(@$themes)) {
#		$ydata->{$fkey}->{themes} = $themes;
		$new_parsing->{$fkey}->{themes} = $themes;
	}

	my ($newdata,$comments) = &extract_setting_comments($prenewdata,$trace);
	say "[$me] filect[$file_ct] data length - comment markers [".length($newdata)."] comments[".scalar(keys %$comments)."]" if $trace;
	if(scalar(keys %$comments)) {
		#$ydata->{$fkey}->{comments} = $comments;
		$new_parsing->{$fkey}->{comments} = $comments;
	}

	my $new_data = &remove_extra_wspace($newdata,$trace);
	
	## make everything lowercase
	my $new_idata = lc $new_data;
	
	say "[$me] filect[$file_ct] trimmed data length [".length($new_data)."]" if $trace;

	my $y = {};
	&extract_topics_to_yml($new_data,$y,$trace);
	if(scalar(keys %$y)) {
#		$ydata->{$fkey}->{extract} = $y;
		$new_parsing->{$fkey}->{extract} = $y;
		say "[$me] filect[$file_ct] fkey[$fkey] data size returned from extract topics, length [".scalar(keys %{ $new_parsing->{$fkey}->{extract} })."]" if $trace;
	} else {
		say "[$me] filect[$file_ct] fkey[$fkey] EXTRACT failed to return data, length[null]" if $trace;
	}

	my $iname = uc $p1;
	push @$inames, $iname;
#	my $fkey = "f".$file_ct;

	$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src} = $filename;
	$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_date} = $p2;
	$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_type} = 'mono';
	$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_parse_key} = $fkey;
	$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{name_no_ext} = $new_data_parsing->{$fkey}->{filenam};
	$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{root_name} = $new_data_parsing->{$fkey}->{filenam};
#	delete $data_parsing->{$fkey}->{filenam};

	$data_coding->{runlinks}->{name_codes}->{$iname} = 1;
	$new_data_postparse->{aquad_meta_parse}->{name_codes}->{$iname} = 1;
	$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{name_code} = $iname;
	if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{role}) {
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{role} = 'ee';
	}
	if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{gender}) {
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{gender} = 'M';
	}
	if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{age_category}) {
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{age_category} = '4';
	}
	if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{audio_rec}) {
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{audio_rec} = 'wav';
	}
	if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{audio_rec_time}) {
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{audio_rec_time} = '1:29';
	}
	if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{group_size}) {
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{group_size} = 4;
	}
	if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{start_time}) {
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{collection_format}->{start_time} = '13:00';
	}
	if(!exists $new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{stakeholder_roles}) {
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{stakeholder_roles}->{primary} = 'property management';
		$new_data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{stakeholder_roles}->{sub_group} = '_na_';
	}

	return 1;
}

sub find_codes {
	my ($cat,$task_id,$trace) = @_;
	my $me = 'PARSE_TOPICS';
	print "= [$my_shortform_server_type][$task_id] = code parsed data;\n" if $trace;

	if(!defined $data_parsing) {
		#my $file = $dir . $yml_dir . $parsingfile;
		my $file = $dir . $yml_dir . $parsingfile;
		say "[PARSING][taskid:$task_id] PostParse NOT loaded, reloading PostParse file[$parsingfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_parsing = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}
	if(!defined $data_parsing or !scalar(keys %$data_parsing)) {
		print "= [$my_shortform_server_type][$task_id] BAD result! No data to code in *data_parsing* var\n" if $runtime;
		return 0;
	}
	if(!defined $data_postparse) {
		#my $file = $dir . $yml_dir . $parsingfile;
		my $file = $dir . $yml_dir . $postparsefile;
		say "[PARSING][taskid:$task_id] PostParse NOT loaded, reloading PostParse file[$parsingfile]...this may take a moment..." if $trace;
		if(open(my $fh, '<', $file)) {
			$data_postparse = LoadFile($file);
		} else {
			die "\nERROR! cannot open [$file] [$!]";
		}
	}
	if(!defined $data_coding or !exists $data_coding->{runlinks}) {
		die "something funky with data_coding file!! [".$data_coding->{runlinks}."] at line[".__LINE__."]\n";
	}

	if(exists $run_status->{backup_data_coding_file_ASAP} and $run_status->{backup_data_coding_file_ASAP}) {
		$codes_dirty->{will_make_data_coding_mods} = 1;
	}
	
	my $ddir = $dir . $yml_dir;

	if($cat==3) {
		####
		## take text extracts and parse them into sentence pieces
		## some data munging will happen based on hardcoded rules (in scrub method)
		## results are stashed in data_postparse
		####
		my $topic_check = 0;
		$me = $me . "_SENTs][taskid:$task_id][cat:$cat";
		print "[$my_shortform_server_type][$me] split topics parsed file\n" if $trace;
		my $sentblocs = {};
		my $wordblocs = {};
		my $phraseblocs = {};
		my $counts_per_lines = {};

		if(defined $data_coding and scalar(keys %$data_coding)) {
			## ahh, yeah, fix some dumass stuff.....
			if(exists $run_status->{will_restructure_multi_data_coding_keys} and $run_status->{will_restructure_multi_data_coding_keys}) {
				## save old codes to a backup file
				my $bakfile = $codingfilenam . "_" . $dtg . ".yml";
				&dump_recovery_file_to_yml($data_coding,$dir,$bakfile,$trace);
				$run_status->{will_restructure_multi_data_coding_keys} = 0;
			}
		}

		## make new_data_postparse...write non-parse existing values into new
		$new_data_postparse = undef;
		if(exists $data_postparse->{aquad_meta_parse}) {
			$new_data_postparse->{aquad_meta_parse} = $data_postparse->{aquad_meta_parse};
		}
#		if(exists $data_post_coding->{aquad_meta_coding}) {
#			$new_data_post_coding->{aquad_meta_coding} = $data_post_coding->{aquad_meta_coding};
#		}
		foreach my $n (keys %{ $run_status->{active_parsing_iname_coding} }) {
			$run_status->{active_parsing_iname_coding}->{$n} = 0;
		}
		foreach my $n (keys %{ $run_status->{active_coding_iname_makestats} }) {
			$run_status->{active_coding_iname_makestats}->{$n} = 0;
		}

		my $fkey_ctr = 0;
		my $iname_ctr = 0;
		foreach my $fkey (keys %$data_parsing) {
			if(!exists $run_status->{active_2_needs_tpliting_fkeys}->{$fkey} or !$run_status->{active_2_needs_tpliting_fkeys}->{$fkey}) {
				## skip...not re-parsing this file (fkey)
				say "= [$my_shortform_server_type][$task_id] skipping this file, fkey[$fkey] no data re-parse" if $trace;

				## bring old existing data forward into new data_postparse
				if($data_parsing->{$fkey}->{src_type}=~/^multi$/i) {
					my $peeps = $data_parsing->{$fkey}->{peeps};
					while(scalar(@$peeps)) {
						my $peep = shift @$peeps;
						my $iname = uc $peep;
						$new_data_postparse->{post_parse}->{$iname} = $data_postparse->{post_parse}->{$iname};
#						if(exists $data_post_coding->{post_coding}->{$iname}) {
#							$new_data_post_coding->{post_coding}->{$iname} = $data_post_coding->{post_coding}->{$iname};
#						}
					}
				} else {
					my $peep = $data_parsing->{$fkey}->{peep};
					my $iname = uc $peep;
					$new_data_postparse->{post_parse}->{$iname} = $data_postparse->{post_parse}->{$iname};
#					if(exists $data_post_coding->{post_coding}->{$iname}) {
#						$new_data_post_coding->{post_coding}->{$iname} = $data_post_coding->{post_coding}->{$iname};
#					}
				}
				if(exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}) {
					$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey} = $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey};
				}
				next;
			}

			my $lines_aref = [];
			if(!exists $data_parsing->{$fkey}->{extract}) {
				die "epic fail....data structure is broke for fkey[$fkey] at [".__LINE__."]\n";
			}
		
			my $extract = $data_parsing->{$fkey}->{extract};

			if($data_parsing->{$fkey}->{src_type}=~/^multi$/i) {

				my $peeps = $data_parsing->{$fkey}->{peeps};
				if(!exists $data_parsing->{$fkey}->{peeps} or !$data_parsing->{$fkey}->{peeps}) {
					die "something funky with peeps [".$data_parsing->{$fkey}->{peeps}."]\n";
				}
				my $blocs = {};
				my $blocks = {};
				
				####
				## scrub multi-src blocks
				####
				my $lines_href = &scrub_multi_topic_href_blocks($peeps,$extract,$blocs,$blocks,$wordblocs,$phraseblocs,$fkey,$trace);
				say "= [$my_shortform_server_type][$task_id] total aquad lines in file[$fkey] [".scalar(keys %$lines_href)."]" if $trace;

				foreach my $lineskey (keys %$lines_href) {
					my $aref = $lines_href->{$lineskey};
					say "= [$my_shortform_server_type][$task_id] aquad lines in file[$fkey] by peep[$lineskey] ct[".scalar(@$aref)."]" if $trace;
					my $iname = uc $lineskey;

					my $lines = $aref;
					say "= [$my_shortform_server_type][$task_id] lines created[".scalar(@$lines)."]" if $trace;

					$new_data_postparse->{post_parse}->{$iname}->{s_cS}->{lines} = $lines;

					if(exists $blocs->{$lineskey}) {
						$new_data_postparse->{post_parse}->{$iname}->{block_sentences} = $blocs->{$lineskey};
					}

					if(exists $blocks->{$iname}) {
						foreach my $tkey (keys %{ $blocks->{$iname} }) {
							say "....check name[$iname] [$tkey]" if $topic_check;
							$new_data_postparse->{post_parse}->{$iname}->{tblocks}->{$tkey} = $blocks->{$iname}->{$tkey};
						}
					}
					$iname_ctr++;
					#$run_status->{active_parsing_iname_coding}->{$iname} = 1;
					$run_status->{active_3_needs_precoding_iname}->{$iname} = 1;
					$run_status->{active_2_needs_tpliting_fkeys}->{$fkey} = 0;
					$run_status->{active_2_done_tsplit_iname}->{$iname} = 1;
				}
				next;
			}

			####
			## single iname scrub...no multi-src scrub
			####
			my $blocs = {};
			$lines_aref = &scrub_topic_href_blocks($extract,$blocs,$wordblocs,$phraseblocs,$trace);
			say "= [$my_shortform_server_type][$task_id] total aquad lines in file[$fkey] [".scalar(@$lines_aref)."]" if $trace;
			
			my $name = $lines_aref->[0];
			if(!defined $lines_aref->[0]) {
				die "horrible death....file name is missing! at [".__LINE__."]\n";
			}
			say "= [$my_shortform_server_type][$task_id] file[$fkey] has name[$name]" if $trace;
			my ($iname,$stuff) = split '_',$name;
			$iname = uc $iname;
			say "= [$my_shortform_server_type][$task_id] interviewee name_code (and data key) [$iname] name[$name]" if $trace;
			$iname_ctr++;
			## indicate that topic split has be done....not sure why coding toggle is set here...
#			$run_status->{active_parsing_iname_coding}->{$iname} = 1;
			## indicate that topic split has be done...to prevent redundant increases in code count use...
			$run_status->{active_parsing_iname_tsplit}->{$iname} = 1;
			$run_status->{active_3_needs_precoding_iname}->{$iname} = 1;
			$run_status->{active_2_needs_tpliting_fkeys}->{$fkey} = 0;
			$run_status->{active_2_done_tsplit_iname}->{$iname} = 1;

		
			say "= [$my_shortform_server_type][$task_id] data coding[$data_coding] [".scalar(keys %{$data_coding->{runlinks}->{name_codes}})."]" if $trace;

			my $found = 0;
			my $nameactive = 0;
		
			my $ifzes = {};
		#&find_ifthen($ifzes,$phraseblocs,$trace);

#		my $lines = &trim_lines($lines_aref,$counts_per_lines,$iname,$trace);
			my $lines = $lines_aref;
			say "= [$my_shortform_server_type][$task_id] lines created[".scalar(@$lines)."]" if $trace;
			$new_data_postparse->{post_parse}->{$iname}->{s_cS}->{lines} = $lines;

			$fkey_ctr++;

		}

		## save new results...hopefully good :)
		## don't wipe out your data file :)....
		if(scalar(keys $new_data_postparse)) {
			&dump_coding_to_yml($new_data_postparse,$ddir,$postparsefile,$trace);
			$codes_dirty->{codes_sorted} = 0;
		}

		## replace data in post parse with new stuff
		$data_postparse->{post_parse} = undef;
		$data_postparse->{post_parse} = $new_data_postparse->{post_parse};

		$run_status->{state_parse} = 2;
		$run_status->{state_parse_info} = 'topics split';
		$run_status->{last_topic_parse_dtg} = $dtg;
		$run_status->{topic_texts_parsed}->{iname_total_count} = scalar(keys %{ $new_data_postparse->{post_parse} });
		$run_status->{topic_texts_parsed}->{parsed_iname_ctr} = $iname_ctr;
		$run_status->{topic_texts_parsed}->{parsed_file_ctr} = $fkey_ctr;
		$run_status->{last_topic_parse_dtg} = $dtg;
		if($iname_ctr) {
			$run_status->{backup_data_coding_file_ASAP} = 1;
		}
	}
	if($cat==5) {
		####
		## NOTE: this step expects a hand coding pre-step...matching topics to at least one MAIN CODE
		## take any hand coded topics and mesh those with existing codes (remote chance of occurance)
		## create post_coding values per sentence in data_postparse...data coder expects to find at least one pre-code
		## MESHING also checks for previous re-code work. If re-codes exists, no new codes will be imported
		## data_postparse file is updated with new code info
		## data_coding is updated with new topic codes (this is the first use of data_coding so a recovery file may be created)
		####
		$me = $me . "_PRECODES][taskid:$task_id][cat:$cat";
		print "[$my_shortform_server_type][$me] set topic pre-codes (from parsed file)\n" if $trace;
		my $blocs = {};
		if(!defined $data_postparse or !exists $data_postparse->{aquad_meta_parse}->{name_codes}) {
			die "something funky with peeps [".$data_postparse->{aquad_meta_parse}->{name_codes}."] line[".__LINE__."]\n";
		}
		if(!defined $data_coding or !exists $data_coding->{runlinks}) {
			die "something funky with data_coding file!! [".$data_coding->{runlinks}."] line[".__LINE__."]\n";
		}

		if(defined $data_coding and scalar(keys %$data_coding)) {
			## check for previous session use of data_coding, if not, assume a backup copy needs to be made
			my $rdir = $dir;
			if(exists $codes_dirty->{will_make_data_coding_mods} and $codes_dirty->{will_make_data_coding_mods}) {
				## save old parse to a backup file
				my $bakfile = $codingfilenam . "_" . $dtg . ".yml";
				&dump_recovery_file_to_yml($data_coding,$rdir,$bakfile,$trace);
				$codes_dirty->{will_make_data_coding_mods} = 0;
				if(exists $run_status->{backup_data_coding_file_ASAP} and $run_status->{backup_data_coding_file_ASAP}) {
					$run_status->{backup_data_coding_file_ASAP} = 0;
				}
			}
		}

		my $iname_ctr = 0;
		foreach my $iname (keys %{ $data_postparse->{aquad_meta_parse}->{name_codes} }) {
			if(!exists $run_status->{active_3_needs_precoding_iname}->{$iname} or !$run_status->{active_3_needs_precoding_iname}->{$iname}) {
				## skip...not re-coding this file data
				say "= [$my_shortform_server_type][$task_id] skipping iname[$iname] - prev existing data good" if $trace;
				next;
			}
#			$run_status->{active_3_needs_precoding_iname}->{$iname} = 1;
#			$run_status->{active_2_needs_tpliting_fkeys}->{$fkey} = 0;
#			$run_status->{active_2_done_tsplit_iname}->{$iname} = 1;

			&mesh_codes($cat,$task_id,$blocs,$iname,$trace);
			
#			$run_status->{active_coding_iname_makestats}->{$iname} = 1;
			$run_status->{active_4_needs_clean_coding_iname}->{$iname} = 1;
			$run_status->{active_3_needs_precoding_iname}->{$iname} = 0;
			$run_status->{active_3_done_precoding_iname}->{$iname} = 1;
			
			$iname_ctr++;
			say "= [$my_shortform_server_type][$task_id] code meshing complete for [".$iname."] ctr[$iname_ctr]" if $trace;
		}
		$run_status->{state_parse} = 3;
		$run_status->{state_parse_info} = 'topics pre-coded';
		$run_status->{last_precode_dtg} = $dtg;
		$run_status->{pre_coded_texts}->{iname_total_count} = scalar(keys %{ $new_data_postparse->{post_parse} });
		$run_status->{pre_coded_texts}->{parsed_iname_ctr} = $iname_ctr;;
	}

	
	if(exists $codes_dirty->{add_codes} and $codes_dirty->{add_codes}) {
		## don't wipe out your data file, yet :)....
		if(defined $data_coding and scalar(keys %$data_coding)) {
			&dump_coding_to_yml($data_coding,$ddir,$codingfile,$trace);
		}
		$codes_dirty->{add_codes} = 0;
		if(exists $codes_dirty->{iname_added_to_codes}) {
			$codes_dirty->{iname_added_to_codes} = 0;
		}
	}
	if(exists $codes_dirty->{codes_sorted} and $codes_dirty->{codes_sorted}) {
		if(defined $data_postparse and scalar(keys %$data_postparse)) {
			&dump_coding_to_yml($data_postparse,$ddir,$postparsefile,$trace);
		}
		$codes_dirty->{codes_sorted} = 0;
	}
	if(exists $codes_dirty->{new_topic_codes} and $codes_dirty->{new_topic_codes}) {
		if(defined $run_config and scalar(keys %$run_config)) {
			&dump_coding_to_yml($run_config,$ddir,$words_file,$trace);
		}
		$codes_dirty->{new_topic_codes} = 0;
	}
	if(exists $codes_dirty->{iname_added_to_codes} and $codes_dirty->{iname_added_to_codes}) {
		if(defined $data_coding and scalar(keys %$data_coding)) {
			&dump_coding_to_yml($data_coding,$ddir,$codingfile,$trace);
		}
		$codes_dirty->{iname_added_to_codes} = 0;
	}

	return 1;
}
sub scrub_topic_href_blocks {
	my ($extract,$sentblocs,$wordblocs,$phraseblocs,$trace) = @_;
	my $me = "SCRUB-MONO";
	say "  [$me] scrubming topic blocks, fkey ct[".scalar(keys %$extract)."]" if $trace;

	my $detail_trace = 1;
	my $trace_embed_codes = 1;
	my $trace_embed_codes2 = 0;
	my @lines = ();
	my $shift_out_filename = 1;
	my $max_tkeys = scalar(keys %$extract);
	my $i = 0;
	my $loop = 1;
	my $j = 1;
	my $iname = undef;
	my $t_char_count = 0;
	my $file_line_ctr = 1;
	my $file_char_ctr = 0;
	my $file_word_ctr = 0;
	my $char_ct = 0;
	my $line_ct = 1;
	while($loop) {
		my $tkey = "t".$i;
		if(!exists $extract->{$tkey}) {
			if($i < $max_tkeys) {
				print "...this value is missing[$i] [$tkey]\n";
				$i++;
				next;
			}
			$loop = 0;
			last;
		}
		my $topic = $extract->{$tkey}->{topic};
		my $tblock = $extract->{$tkey}->{block};
		if($i == 0) {
			my @bparts = split /[!\.\?]/,$tblock;
			say "file name[".$bparts[0]."] has topic codel[".$topic."]";
			my $stuff = undef;
			($iname,$stuff) = split '_',$bparts[0];
			$iname = uc $iname;
		
			if(!defined $bparts[0] or !$bparts[0]) {
				$i++;
				next;
			}
			if($bparts[0]=~/^\s+$/) {
				$i++;
				next;
			}
			push @lines,$bparts[0];
			$line_ct++;
			$shift_out_filename = 0;
			$i++;
			next;
		}
		if($extract->{$tkey}->{block}=~/_BLANK_/i) {
			say "[$me] [$iname] this [$tkey] for topic[".$extract->{$tkey}->{topic}."] is blank...skipping" if $trace;
			$i++;
			next;
		}

		## make topic uppercase for callout and comparisons
		$new_data_postparse->{post_parse}->{$iname}->{tblocks}->{$tkey}->{topic} = $topic;
		$new_data_postparse->{aquad_meta_parse}->{topic_lists}->{$iname}->{$i} = $topic;
		$data_postparse->{aquad_meta_parse}->{topic_lists}->{$iname}->{$i} = $topic;
		my $nctopic = $topic;
		my $ttopic = uc $topic;
		$new_data_postparse->{aquad_meta_parse}->{topic_lists_uc}->{$iname}->{$ttopic} = $i;
		$data_postparse->{aquad_meta_parse}->{topic_lists_uc}->{$iname}->{$ttopic} = $i;
		if(!exists $new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic}) {
			$new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} = 0;
			$data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} = 0;
		}
		$new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} = $new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} + 1;
		$data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} = $new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic};

#		$new_data_postparse->{post_parse}->{$iname}->{tblocks}->{$tkey}->{block} = $tblock;
		$topic = uc $topic;
		
		say "[$me] [$iname] topic, index[$i] ct[$j] topic[".$topic."] " if $detail_trace;

		my $count1 = 0;
		my $re1 =    qr/
						([\[\]\"])
						(?(?{$count1++})|(*FAIL))
					/x;
		my $tblock_str = $tblock;
		$tblock_str=~ s/$re1//g;
		$tblock_str =~ s/##COM\d+##\s//gi;
		$tblock_str =~ s/\s##COM\d+##//gi;
		
		$tblock =~ s/[\?]+\s/\(\?\)\. /g;
		$tblock =~ s/[!]+\s/\(!\)\./g;
		$tblock =~ s/##COM\d+##\s//gi;
		$tblock =~ s/\s##COM\d+##//gi;
		my @bparts = split /[\.]/,$tblock;
		my $ctr = 0;
#		my $t_line_ct = 1;
		my $topic_braces = "[" . $topic . "].";
		push @lines,$topic_braces;
		$char_ct = $char_ct + length($topic_braces) + 1;
		$line_ct++;
		my $topic_char_ctr = 0;
		my $t_str = '';
		for (my $ii=0; $ii<scalar(@bparts); $ii++) {
			if(!$bparts[$ii]) {
				next;
			}
			if($bparts[$ii]=~/^\s+$/) {
				next;
			}
			my $counts_href = {};
			my $str = trim_line($bparts[$ii],$counts_href,$trace);
			my $string3 = $str;

			my $count2 = 0;
			my $count3 = 0;
			my $count4 = 0;
			my $re2 =    qr/
							([\[\]\"\(\)\?\,\;\:])
							(?(?{$count2++})|(*FAIL))
						/x;
			my $re3 =    qr/
							([\[\]\"])
							(?(?{$count3++})|(*FAIL))
						/x;
						

			## make strdata lowercase for comparisons
			my $strdata = lc $str;
			my $string1 = $str;

			$string1 =~ s/$re1//g;
			## remove comment strings and markers
			my $newstr = $string1;
			$newstr =~ s/##COM\d+##\s//gi;
			$newstr =~ s/\s##COM\d+##//gi;

			## compress any 'spaced' punctuation because of [] clarifications
			$newstr =~ s/(\s,)/,/gi;
			
			## if string stripping eliminates all characters....do not create a sentence entry...
			if(!$newstr or $newstr=~/^\s+$/) {
				next;
			}
			
			## check for in-text coding
			if($newstr=~/\^\//) {
				say "[$my_shortform_server_type][$me] iname[".$iname."] tkey[$tkey] topic[$topic] prev_str[$newstr]" if $trace_embed_codes2;
				my @cparts = split /\^\//,$newstr;
				my @partsparts = ();
				for (my $j=0; $j<scalar(@cparts); $j++) {
					if($cparts[$j]) {
						if($cparts[$j]=~/\/\^\s+/) {
							## topic level code
							my ($leadingcode,$strmeat) = split /\/\^\s+/,$cparts[$j];
							push @partsparts,$strmeat;
							if($leadingcode) {
								## set an in-text code
								if(exists $topic_to_code_mapping->{main_codes}->{$nctopic}) {
									if($topic_to_code_mapping->{main_codes}->{$nctopic} eq $leadingcode) {
										## do nothing for now...
									} else {
										if(!exists $topic_to_code_mapping->{alt_codes}->{$nctopic}) {
											$topic_to_code_mapping->{alt_codes}->{$nctopic} = $leadingcode;
											$data_coding->{runlinks}->{add_codes}->{$leadingcode} = 1;
											$codes_dirty->{new_topic_codes} = 1;
											$codes_dirty->{add_codes} = 1;
											say "[$my_shortform_server_type][$me] [".$iname."] tkey[$tkey] topic[$topic] set ALT topic code[$leadingcode] - also to ADD_CODES" if $trace_embed_codes;
										}
									}
								} else {
									$topic_to_code_mapping->{main_codes}->{$nctopic} = $leadingcode;
									$codes_dirty->{new_topic_codes} = 1;
									$data_coding->{runlinks}->{add_codes}->{$leadingcode} = 1;
									$codes_dirty->{add_codes} = 1;
									say "[$my_shortform_server_type][$me] [".$iname."] tkey[$tkey] topic[$topic] Set MAIN topic code[$leadingcode] - also to ADD_CODES" if $trace_embed_codes;
								}
							}
						}
						if($cparts[$j]=~/\/s\^\s+/) {
							## sentence level code
							my ($leadingcode,$strmeat) = split /\/s\^\s+/,$cparts[$j];
							push @partsparts,$strmeat;
							if($leadingcode) {
								## set an in-text code
								my $_sindex = $ctr+1;
								my $_tskey = $tkey . "s" . $_sindex;
								my $size = 1;
								if(exists $new_data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$_tskey}->{codes}) {
									$size = scalar(keys %{ $new_data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$_tskey}->{codes} });
									$size++;
								}
								$new_data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$_tskey}->{codes}->{$size} = $leadingcode;
								$data_coding->{runlinks}->{add_codes}->{$leadingcode} = 1;
								$codes_dirty->{add_codes} = 1;
								my $ct = 1;
								if(exists $data_coding->{runlinks}->{hot_codes}->{$leadingcode} and $data_coding->{runlinks}->{hot_codes}->{$leadingcode}) {
									$ct = $data_coding->{runlinks}->{hot_codes}->{$leadingcode};
									$ct++;
								}
								say "[$my_shortform_server_type][$me] [".$iname."] tkey[$tkey] topic[$topic] tskey[$_tskey] size[$size] sent CODE[$leadingcode] - also to ADD_CODES, hotcode ct[$ct]" if $trace_embed_codes;
								if(!exists $run_status->{active_parsing_iname_tsplit}->{$iname} or !$run_status->{active_parsing_iname_tsplit}->{$iname}) {
									$data_coding->{runlinks}->{hot_codes}->{$leadingcode} = $ct;
									say "[$my_shortform_server_type][$me] [".$iname."] tkey[$tkey] topic[$topic] tskey[$_tskey] sent CODE[$leadingcode] - add hotcode, ct[$ct]" if $trace_embed_codes;
								}
								if(!exists $topic_to_code_mapping->{main_codes}->{$nctopic}) {
									$topic_to_code_mapping->{main_codes}->{$nctopic} = $leadingcode;
									$codes_dirty->{new_topic_codes} = 1;
								}
							}
						}
					}
				}
				if(scalar(@partsparts)) {
					my $mstr = '';
					for (my $jj=0; $jj<scalar(@partsparts); $jj++) {
						if($mstr) {
							$mstr = $mstr . " " . $partsparts[$jj];
						} else {
							$mstr = $partsparts[$jj];
						}
					}
					if($mstr) {
						$newstr = $mstr;
					}
				}
				say "[$my_shortform_server_type][$me] [".$iname."] tkey[$tkey] topic[$topic] end_str[$newstr]" if $trace_embed_codes2;
			}

			$ctr++;
			my $k = $ctr;
			$sentblocs->{$tkey}->{$k} = $str;
			$new_data_postparse->{post_parse}->{$iname}->{block_sentences}->{$tkey}->{$k} = $str;

			my $char_len = length($newstr);
			## add punctuation at end...it is needed for all of the following
			$newstr = $newstr . ".";
			
			## make atx and txt file string			
			if($t_str) {
				$t_str = $t_str . " ";
			}
			$t_str = $t_str . $newstr;
			my $tskey = $tkey . "s" . $k;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{begin}->{chars} = $file_char_ctr;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{begin}->{topic_chars} = $char_ct;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{begin}->{filept_chars_before_str} = $file_char_ctr;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{begin}->{topicpt_chars_before_str} = $topic_char_ctr;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{begin}->{multi_filept_chars_before_str} = $file_char_ctr;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{begin}->{multi_topicpt_chars_before_str} = $topic_char_ctr;
			$file_char_ctr = $file_char_ctr + $char_len;
			$topic_char_ctr = $topic_char_ctr + $char_len;
			
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{chars} = $char_len;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{str_chars} = $counts_href->{chars};
#			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{topic_line} = $k;
#			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{file_line} = $line_ct;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{topic_line_num} = $k;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{file_line_num} = $file_line_ctr;
			$char_ct = $char_ct + $char_len;

			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{ts_total_lines} = 1;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{words} = $counts_href->{words};
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{atx_block_sentence} = $k;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{sentence} = $newstr;
			$file_word_ctr = $file_word_ctr + $counts_href->{words};

			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map}->{$k} = $tskey;
			$line_ct++;
			$file_line_ctr++;

			## set lowercase, retain punctuation
			$newstr = lc $newstr;
			## push scrubbed block onto lines array
			push @lines,$newstr;

			## retain CAPS and punctuation for phrase blocks
			$string3 =~ s/$re3//g;
			$phraseblocs->{$j}->{$k} = $string3;
						
			## set lowercase, clear all non-alpha chars for word counts
			my $string2 = $strdata;
			$string2 =~ s/$re2//g;
			$wordblocs->{$j}->{$k} = $string2;

			$counts_href = undef;
		}
		## make atx and txt file stores
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{atx_block} = $t_str;
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{topic} = $topic;
#		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{atxblock} = $t_str;
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{txt_block} = $tblock_str;
#		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{sentence_count} = $ctr;
#		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{iname_sentence_count} = $iname_sent_ct;
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{iname_sentence_count} = $ctr;
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{multi_iname_sentence_count} = $ctr;
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{begin_chars_topic} = $t_char_count;
		my $t_len = length($t_str) + 1;
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{length_chars_topic} = $t_len;
		$t_char_count = $t_char_count + $t_len;

		
		$j++;
		$i++;
	}

	$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{file_data}->{total}->{str_chars} = $file_char_ctr;
	$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{file_data}->{total}->{words} = $file_word_ctr;
	$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{file_data}->{total}->{lines} = $file_line_ctr;
	$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{file_data}->{average}->{chars_per_word} = $file_char_ctr / $file_word_ctr;
	
	say "Scrubbed topic ct[".scalar(keys %$extract)."] includes filename[$shift_out_filename] yielding; wordblock ct[".scalar(keys %{$wordblocs})."] phrasebloc ct[".scalar(keys %{$phraseblocs})."] lines[".scalar(@lines)."]" if $trace;
	return \@lines;
}
sub scrub_multi_topic_href_blocks {
	my ($peeps,$extract,$sentblocs,$blocks,$wordblocs,$phraseblocs,$file_parse_key,$trace) = @_;
	my $me = "SCRUB-MULTI";
	say "  [$me] scrubming multi topic-blocks, tkey ct[".scalar(keys %$extract)."]" if $trace;

	my $detail_trace = 1;
	my $trace_embed_codes = 1;
	my $trace_embed_codes2 = 0;
	my $peep_trace = 0;
	my $multi_trace = 1;

	## ...to fix some bad tskey referencing in the coder app....
	my $prev_head_key = 're_codes';
	my $retain_head_key = 'prev_codes';
	my $new_re_head_key = 'new_re_codes';
	
	my $topics = undef;
	my $tblocks = undef;
	my $max_tkeys = scalar(keys %$extract);
	my @lines = ();
	my $peeplines = {};
	my $peepchars = {};
	my $file_peepchars = {};
	my $file_peeplines = {};
	my $file_peepwords = {};
	my $file_inamewords = {};
	my $shift_out_filename = 1;
	my $topic_filter = {};
	my $topic_ifilter = {};
	say "[$my_shortform_server_type][$me] multi scrubbing for peeps, peeps ct[".scalar(@$peeps)."} topic ct[".scalar(keys %$extract)."] href blocs[".scalar(keys %$sentblocs)."]" if $trace;

	my $i = 0;
	my $j = 1;
	my $loop = 1;
	my $file_line_ctr = 0;
	my $file_char_ctr = 0;
	my $line_ctr = {};
	my $pctr = {};
	while($loop) {
		my $tkey = "t".$i;
		if(!exists $extract->{$tkey}) {
			if($i < $max_tkeys) {
				print "...this value is missing[$i] [$tkey]\n";
				$i++;
				next;
			}
			$loop = 0;
			last;
		}
		my $topic = $extract->{$tkey}->{topic};
		my $tblock = $extract->{$tkey}->{block};
		if($i == 0) {
			####
			## at the start of each file, init
			## - the sentence ctr, exclude the filename
			## - the line count to include filename
			## - add filename as first line (not really needed...but can be helpful
			####
			say "[$my_shortform_server_type][$me] topic key[$tkey] name[".$topic."] has bloc length[".length($tblock)."]" if $trace;
			my @namparts = split /[!\.\?]/,$tblock;
			say "file name[".$namparts[0]."] has topic codel[".$topic."]" if $trace;
			if(!defined $tblock or !$tblock) {
				warn "multiparrse - tblock [$tkey] is empty!!";
				$i++;
				next;
			}
			if($tblock=~/^\s+$/) {
				warn "multiparrse - tblock [$tkey] is empty!!";
				$i++;
				next;
			}
			for (my $jj=0; $jj<scalar(@$peeps); $jj++) {
				my $reg = $peeps->[$jj];
				if(!exists $pctr->{$reg}) {
					$pctr->{$reg} = 0;
				}
				$peeplines->{$reg} = [];
				my $g = $peeplines->{$reg};
				push @$g,$tblock;
				say "[$my_shortform_server_type][$me] topic key[$tkey] name[".$tblock."] peep[$reg] " if $trace;
				$line_ctr->{$reg} = 2; ## set counter to next line value
			}

			$i++;
			$file_line_ctr++;
			$shift_out_filename = 0;			
			next;
		}
		if($extract->{$tkey}->{block}=~/_BLANK_/i) {
			say "[$me] file[$file_parse_key] tkey[$tkey] for topic[".$extract->{$tkey}->{topic}."] is blank...skipping" if $trace;
			$i++;
			$file_line_ctr++;
			next;
		}
		## make topic uppercase for callout and comparisons
		my $nctopic = $topic;
		my $ttopic = $topic;
		$topic = uc $topic;

		if(!exists $new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic}) {
			$new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} = 0;
			$data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} = 0;
		}
		$new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} = $new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} + 1;
		$data_postparse->{aquad_meta_parse}->{topics}->{$ttopic} = $new_data_postparse->{aquad_meta_parse}->{topics}->{$ttopic};

		## initialize the sentence by peep counters within the topic
		for (my $jj=0; $jj<scalar(@$peeps); $jj++) {
			$pctr->{$peeps->[$jj]} = 0;
		}

		say "[$my_shortform_server_type][$me] topic[".$topic."] t-index[$i]" if $detail_trace;

		
		my $count1 = 0;
		my $re1 =    qr/
						([\[\]\"])
						(?(?{$count1++})|(*FAIL))
					/x;
		my $tblock_str = $tblock;
		$tblock_str=~ s/$re1//g;
		$tblock_str =~ s/##COM\d+##\s//gi;
		$tblock_str =~ s/\s##COM\d+##//gi;
		$tblock_str =~ s/##COM\d+##//gi;
		
		$tblock =~ s/[\?]+\s/\(\?\)\. /g;
#		$tblock =~ s/[\?]+/\(\?\)\./g;
		$tblock =~ s/[!]+\s/\(!\)\./g;
#		$tblock =~ s/[!]+/\(!\)\./g;
		$tblock =~ s/##COM\d+##\s//gi;
		$tblock =~ s/\s##COM\d+##//gi;
#		$tblock =~ s/\s##COM\d+##//gi;
		say "[$my_shortform_server_type][$me] topic[".$topic."] index[$i] ct[$j] tblock len[".length($tblock)."]" if $trace;

		my $t_str = '';
		my $t_char_ct = 0;
		my $t_line_ct = 1;
		my $topic_line_ctr = 1;
		my $topic_line_ctr_bad = 1;
		my %multi_text = ();
		my %multi_text_new = ();
		my $sctr = 0;
		my $sctr_new = 1;
		my $topic_braces = "[" . $topic . "].";
		$t_char_ct = $t_char_ct + length($topic_braces);
		$t_line_ct++;
#		++;

		my $topicbypeeps_txt = {};
		my $topicbypeeps_ctr = {};
		my $topicbypeeps_map = {};
		my $topicbypeeps_bad_map = {};
		my %topic_txt = ();
		my %iname_pos_map = ();
		
		my @pparts = split /\+\\/,$tblock;

		for (my $ii=0; $ii<scalar(@pparts); $ii++) {
			if(!$pparts[$ii]) {
				say " .. not defined at index ii[$ii]" if $detail_trace;
				next;
			}
			if($pparts[$ii]=~/^\s+$/) {
				say " .. blank spaces at index ii[$ii]" if $detail_trace;
				next;
			}
			my $peep = undef;
#			say "  peep ct[".scalar(@$peeps)."] pparts[".$pparts[$ii]."]";
			for (my $jj=0; $jj<scalar(@$peeps); $jj++) {
				my $reg = $peeps->[$jj];
#				say "  topic[".$topic."] peep, reg[$reg] text[".$pparts[$ii]."]" if $peep_trace;
				if($pparts[$ii]=~/^$reg\\\+/i) {
					say "  topic[".$topic."] found peep, reg[$reg] text[".$pparts[$ii]."]" if $peep_trace;
					$peep = $reg;
				}
			}
			if(!$peep) {
				warn "[multi-parse] failed to find a good peep!";
				die "\tdying to fix\n";
				next;
			}
			
			## peep found, set UC iname and continue
			my $iname = uc $peep;
			my $plines = $peeplines->{$peep};
			$sctr++;

			#push @lines,$topic_braces;
			my $t_char_count = 0;
			my $char_ct = 0;
			my $line_ct = 1;
#			say "    check peep[".$reg."] is in topic lock, size[".length($tblock)."]" if $detail_trace;

			$new_data_postparse->{aquad_meta_parse}->{topic_lists}->{$iname}->{$i} = $ttopic;
			if(!exists $topic_ifilter->{$i}->{$iname}) {
				if(!exists $topic_filter->{$i}) {
					if(!exists $new_data_postparse->{aquad_meta_parse}->{topics}->{$topic}) {
						$new_data_postparse->{aquad_meta_parse}->{topics}->{$topic} = 0;
					}
					$new_data_postparse->{aquad_meta_parse}->{topics}->{$topic} = $new_data_postparse->{aquad_meta_parse}->{topics}->{$topic} + 1;
					$topic_filter->{$i} = 1;
				}
				$topic_ifilter->{$i}->{$iname} = 1;
			}
			$iname_pos_map{$topic_line_ctr} = $iname;

			####
			## Note, the backslash "\" does not escape itself...no clue
			## so, to match "\\+", only the "+" is escaped for /\\\+/
			####
			my ($lead,$meat) = split /\\\+/,$pparts[$ii];
			my @bparts = split /[\.]/,$meat;
			say "[$my_shortform_server_type][$me] topic[".$topic."] peep[$peep] t-index[$i] sent ctr[$sctr] peep sctr[".$pctr->{$peep}."]-pre-incr" if $detail_trace;
#			say "[$my_shortform_server_type][$me] matched peep[".$peep."]lead[$lead] peepblock size[".length($pparts[$ii])."] sentences for peep[".scalar(@bparts)."] start sent ct[$sctr]" if $detail_trace;
#			say "[$my_shortform_server_type][$me] for peep [".$peep."] peepmatch[$lead] sparts[".scalar(@bparts)."] sentence ct so far[".$pctr->{$peep}."]" if $detail_trace;

			for (my $iii=0; $iii<scalar(@bparts); $iii++) {
				if(!$bparts[$iii]) {
					next;
				}
				if($bparts[$iii]=~/^\s+$/) {
					## data field is blank, skip
					next;
				}
				if($pctr->{$peep}==0) {
					push @$plines,$topic_braces;
					$line_ctr->{$peep}++;
					$char_ct = $char_ct + length($topic_braces) + 1;
					$peepchars->{$peep} = length($topic_braces);
				}

				my $counts_href = {};
				my $str = trim_line($bparts[$iii],$counts_href,$trace);
				my $string3 = $str;

				my $count2 = 0;
				my $count3 = 0;
				my $re2 =    qr/
								([\[\]\"\(\)\?\,\;\:])
								(?(?{$count2++})|(*FAIL))
							/x;
				my $re3 =    qr/
							([\[\]\"])
							(?(?{$count3++})|(*FAIL))
						/x;
		
				## make strdata lowercase for comparisons
				my $strdata = lc $str;
				my $string1 = $str;
				
				$string1 =~ s/$re1//g;
				## remove comment placeholders for text coding
				my $newstr = $string1;
				$newstr =~ s/##COM\d+##\s//gi;
				$newstr =~ s/\s##COM\d+##//gi;

				## compress any 'spaced' punctuation because of [] clarifications
				$newstr =~ s/(\s,)/,/gi;
			
				## if string stripping eliminates all characters....do not create a sentence entry...
				if(!$newstr or $newstr=~/^\s+$/) {
					next;
				}
				$pctr->{$peep} = $pctr->{$peep} + 1;
				my $k = $pctr->{$peep};

			## check for in-text coding
			## this is not ready because the non-peep case still needs to be addressed
			if($newstr=~/\^\//) {
				say "[$my_shortform_server_type][$me] iname[".$peep."] tkey[$tkey] topic[$topic] prev_str[$newstr]" if $trace_embed_codes2;
				## topic coding is peep neutral
				my @cparts = split /\^\//,$newstr;
				my @partsparts = ();
				for (my $j=0; $j<scalar(@cparts); $j++) {
					if($cparts[$j]) {
						if($cparts[$j]=~/\/\^\s+/) {
							## topic level code
							my ($leadingcode,$strmeat) = split /\/\^\s+/,$cparts[$j];
							push @partsparts,$strmeat;
							if($leadingcode) {
								## set an in-text code
								if(exists $topic_to_code_mapping->{main_codes}->{$nctopic}) {
									if($topic_to_code_mapping->{main_codes}->{$nctopic} eq $leadingcode) {
										## do nothing for now...
									} else {
										if(!exists $topic_to_code_mapping->{alt_codes}->{$nctopic}) {
											$topic_to_code_mapping->{alt_codes}->{$nctopic} = $leadingcode;
											$data_coding->{runlinks}->{add_codes}->{$leadingcode} = 1;
											$codes_dirty->{new_topic_codes} = 1;
											$codes_dirty->{add_codes} = 1;
											say "[$my_shortform_server_type][$me] [".$peep."] tkey[$tkey] topic[$topic] set ALT topic code[$leadingcode] - also to ADD_CODES" if $trace_embed_codes;
										}
									}
								} else {
									$topic_to_code_mapping->{main_codes}->{$nctopic} = $leadingcode;
									$codes_dirty->{new_topic_codes} = 1;
									$data_coding->{runlinks}->{add_codes}->{$leadingcode} = 1;
									$codes_dirty->{add_codes} = 1;
									say "[$my_shortform_server_type][$me] [".$peep."] tkey[$tkey] topic[$topic] Set MAIN topic code[$leadingcode] - also to ADD_CODES" if $trace_embed_codes;
								}
							}
						}
						if($cparts[$j]=~/\/s\^\s+/) {
							## sentence level code
							my ($leadingcode,$strmeat) = split /\/s\^\s+/,$cparts[$j];
							push @partsparts,$strmeat;
							if($leadingcode) {
								## set an in-text code
								my $_sindex = $pctr->{$peep} + 1;
								my $_tskey = $tkey . "s" . $_sindex;
								my $size = 1;
								if(exists $new_data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$_tskey}->{codes}) {
									$size = scalar(keys %{ $new_data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$_tskey}->{codes} });
									$size++;
								}
								$new_data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$_tskey}->{codes}->{$size} = $leadingcode;
								$data_coding->{runlinks}->{add_codes}->{$leadingcode} = 1;
								$codes_dirty->{add_codes} = 1;
								my $ct = 1;
								if(exists $data_coding->{runlinks}->{hot_codes}->{$leadingcode} and $data_coding->{runlinks}->{hot_codes}->{$leadingcode}) {
									$ct = $data_coding->{runlinks}->{hot_codes}->{$leadingcode};
									$ct++;
								}
								say "[$my_shortform_server_type][$me] [".$peep."] tkey[$tkey] topic[$topic] tskey[$_tskey] size[$size] sent CODE[$leadingcode] - also to ADD_CODES, hotcode ct[$ct]" if $trace_embed_codes;
								if(!exists $run_status->{active_parsing_iname_tsplit}->{$iname} or !$run_status->{active_parsing_iname_tsplit}->{$iname}) {
									$data_coding->{runlinks}->{hot_codes}->{$leadingcode} = $ct;
									say "[$my_shortform_server_type][$me] [".$peep."] tkey[$tkey] topic[$topic] tskey[$_tskey] sent CODE[$leadingcode] - add hotcode, ct[$ct]" if $trace_embed_codes;
								}
								if(!exists $topic_to_code_mapping->{main_codes}->{$nctopic}) {
									$topic_to_code_mapping->{main_codes}->{$nctopic} = $leadingcode;
									$codes_dirty->{new_topic_codes} = 1;
								}
							}
						}
					}
				}
				if(scalar(@partsparts)) {
					my $mstr = '';
					for (my $jj=0; $jj<scalar(@partsparts); $jj++) {
						if($mstr) {
							$mstr = $mstr . " " . $partsparts[$jj];
						} else {
							$mstr = $partsparts[$jj];
						}
					}
					if($mstr) {
						$newstr = $mstr;
					}
				}
				say "[$my_shortform_server_type][$me] [".$peep."] tkey[$tkey] topic[$topic] end_str[$newstr]" if $trace_embed_codes2;
			}
			## end of coding

				if(!exists $topicbypeeps_ctr->{$iname}) {
					$topicbypeeps_ctr->{$iname} = 0;
				}
				## lines by peep
				$topicbypeeps_ctr->{$iname} = $topicbypeeps_ctr->{$iname} + 1;
				## text for that line
				$topicbypeeps_txt->{$iname}->{ $topicbypeeps_ctr->{$iname} } = $newstr;
				## map line to actual topic line
				$topicbypeeps_map->{$iname}->{ $topicbypeeps_ctr->{$iname} } = $topic_line_ctr;
				## text for topic line...kind of redundant...
				$topic_txt{$topic_line_ctr} = $newstr;
				
				####!!!!
				## also handle some bad key mapping due to bad increments...
				## the $sctr has an initial increment when starting the parse of each peep (because it zero, not 1)
				## that adds a space between keys when switching peeps.
				####
				$topicbypeeps_bad_map->{$iname}->{ $topicbypeeps_ctr->{$iname} } = $sctr;

				$sentblocs->{$peep}->{$tkey}->{$k} = $str;
				$new_data_postparse->{post_parse}->{$iname}->{block_sentences}->{$tkey}->{$k} = $str;

				## add punctuation at end...it is needed for all of the following
				$newstr = $newstr . ".";

				## make atx and txt file string
				if($t_str) {
					$t_str = $t_str . " ";
				}
				$t_str = $t_str . $newstr;
				my $tskey = $tkey . "s" . $sctr;
				if(!$tskey or !length($tskey)) {
					say "[$my_shortform_server_type][$me] set multi_text, WTF!! no tskey [$tskey]";
					die "fix this...\n";
				}
				my $tskey2 = $tkey . "s" . $sctr_new;


				my $char_len = length($newstr);
				$peepchars->{$peep} = $peepchars->{$peep} + $char_len;

				$file_peepwords->{$peep} = $file_peepwords->{$peep} + $counts_href->{words};
			
				$t_line_ct++;
				$char_ct = $char_ct + $char_len;
				$t_char_ct = $t_char_ct + $char_len;
				$line_ctr->{$peep}++;

				## set lowercase, retain punctuation
				$newstr = lc $newstr;
						
				push @$plines,$newstr;
		
				## retain CAPS and punctuation
				$string3 =~ s/$re3//g;
				$phraseblocs->{$j}->{$peep}->{$k} = $string3;

				## set lowercase, clear all non-alpha chars
				my $string2 = $strdata;
				$string2 =~ s/$re2//g;
				$wordblocs->{$j}->{$peep}->{$k} = $string2;
				$multi_text{$sctr} = $iname;
				$multi_text_new{$sctr} = $sctr_new;
				say "[$my_shortform_server_type][$me] set multi_text, tkey[$tkey] txt key[$sctr] iname[$iname] multi_text size[".scalar(keys %multi_text)."]" if $multi_trace;
				$sctr++;
				$sctr_new++;
				$topic_line_ctr++;

				$counts_href = undef;

			}
			say "[$my_shortform_server_type][$me] topicct[$j] total sentence ct[$sctr] blocs size[".scalar(keys %{$sentblocs->{$j}->{$peep}})."] phraseblocks size[".scalar(keys %{$phraseblocs->{$j}->{$peep}})."] peep lines[".scalar(@$plines)."]" if $detail_trace;

			## make atx and txt file stores
		}

		my %topic_txt_chars = ();
		my %file_txt_chars = ();
		my %file_txt_lines = ();
		my $chars_ctr = 0;
		my $re_tblock = '';
#		my $post_iname = '_NONE_';
		foreach my $line_ctr (sort {$a <=> $b} keys %topic_txt) {
			my $puthere = '';
			if(exists $iname_pos_map{$line_ctr}) {
#				$post_iname = ;
				$puthere = "(" . $iname_pos_map{$line_ctr} . ") ";
			}
			if($topic_txt{$line_ctr}) {
				$chars_ctr = $chars_ctr + length($topic_txt{$line_ctr});
				$re_tblock = $re_tblock . " " .  $puthere . $topic_txt{$line_ctr} . ".";
			}
			$topic_txt_chars{$line_ctr} = $chars_ctr;
			$file_txt_chars{$line_ctr} = $file_char_ctr + $chars_ctr;
			$file_txt_lines{$line_ctr} = $file_line_ctr + $line_ctr;
		}

		$file_line_ctr = $file_line_ctr + scalar(keys %topic_txt);
		$file_char_ctr = $file_char_ctr + $chars_ctr;

		## peeps split up, set topic info for each peep and all
		foreach my $iname (keys %{ $topicbypeeps_txt }) {
			my $new_block = '';
			my $iname_chars_ctr = 0;
			my $iname_sent_ct = 0;
			if(!exists $file_inamewords->{$iname}) {
				$file_inamewords->{$iname} = 0;
			}
			foreach my $_ctr (sort {$a <=> $b} keys %{$topicbypeeps_txt->{$iname}}) {

				my $_tskey = $tkey . "s" . $_ctr;
				my $_line_ctr = $topicbypeeps_map->{$iname}->{ $_ctr };
				my $_bad_ctr = $topicbypeeps_bad_map->{$iname}->{ $_ctr };
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{begin}->{chars} = $file_peepchars->{$iname} + $iname_chars_ctr;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{begin}->{topic_chars} = $iname_chars_ctr;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{begin}->{filept_chars_before_str} = $file_peepchars->{$iname} + $iname_chars_ctr;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{begin}->{topicpt_chars_before_str} = $iname_chars_ctr;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{begin}->{multi_filept_chars_before_str} = $file_txt_chars{$_line_ctr} + $iname_chars_ctr;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{begin}->{multi_topicpt_chars_before_str} = $topic_txt_chars{$_line_ctr} + $iname_chars_ctr;

				## make sure field has data
				my $char_len = 0;
				if($topicbypeeps_txt->{$iname}->{$_ctr}) {
					$new_block = $new_block . ". " . $topicbypeeps_txt->{$iname}->{$_ctr};
					$iname_chars_ctr = $iname_chars_ctr + length($topicbypeeps_txt->{$iname}->{$_ctr});
					$char_len = length($topicbypeeps_txt->{$iname}->{$_ctr});
				}
				my $counts_href = {};
				my $str = trim_line($topicbypeeps_txt->{$iname}->{$_ctr},$counts_href,$trace);

#				$topicbypeeps_txt->{$iname}->{ $topicbypeeps_ctr->{$iname} } = $newstr;
				my $_remap_tskey = $tkey  . "s" . $_line_ctr;
				my $_bad_tskey = $tkey  . "s" . $_bad_ctr;
				
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{chars} = $char_len;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{str_chars} = $counts_href->{chars};
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{topic_line_num} = $_ctr;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{file_line_num} = $file_peeplines->{$iname} + $_ctr;
#				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{multi_topic_line_num} = $_line_ctr;

				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{ts_total_lines} = 1;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{words} = $counts_href->{words};
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{atx_block_sentence} = $_ctr;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{atx_multi_tblock_sentence_index} = $_line_ctr;
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{sentence} = $topicbypeeps_txt->{$iname}->{$_ctr};
				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map}->{$_ctr} = $_remap_tskey;
				$file_inamewords->{$iname} = $file_inamewords->{$iname} + $counts_href->{words};

				$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{multi_parse_structure} = 1;
				$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$_remap_tskey}->{iname} = $iname;
				$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$_remap_tskey}->{tskey_map} = $_tskey;
				$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$_remap_tskey}->{counts}->{topic_line_num} = $_line_ctr;
				$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$_remap_tskey}->{counts}->{file_line_num} = $file_txt_lines{$_line_ctr};
				$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$_remap_tskey}->{begin_line}->{pt_file_chars} = $file_txt_chars{$_line_ctr} + $iname_chars_ctr;
				$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$_remap_tskey}->{begin_line}->{pt_topic_chars} = $topic_txt_chars{$_line_ctr} + $iname_chars_ctr;
				

				if(exists $run_status->{will_restructure_multi_data_coding_keys} and $run_status->{will_restructure_multi_data_coding_keys}) {
					## use with care...code has a bug and will trash old hash ptrs...
					if(exists $data_coding->{$iname}->{$prev_head_key}) {
						if(exists $data_coding->{$iname}->{$prev_head_key}->{sentences} and scalar(keys %{ $data_coding->{$iname}->{$prev_head_key}->{sentences} })) {
							if(exists $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey} and scalar(keys %{ $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey} })) {
								foreach my $kkey (keys %{ $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey} }) {
									if($kkey=~/^tempcode/i or $kkey=~/^sentence/i) {
										## skip
										next;
									}
	#								$data_coding->{$iname}->{$retain_head_key}->{sentences}->{$_bad_tskey}->{$kkey} = $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey};
									if($data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey}=~/HASH/i and scalar(keys %{ $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey} }) ) {
										foreach my $k2key (keys %{ $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey} }) {
											$data_coding->{$iname}->{$new_re_head_key}->{sentences}->{$_tskey}->{$kkey}->{$k2key} = $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey}->{$k2key}; 
											$data_coding->{$iname}->{$retain_head_key}->{sentences}->{$_tskey}->{$kkey}->{$k2key} = $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey}->{$k2key}; 
	#										delete $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey}->{$k2key}; 
										}
									} else {
	#									delete $data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey}; 
									}
	#								$data_coding->{$iname}->{$prev_head_key}->{sentences}->{$_bad_tskey}->{$kkey} = undef; 
								}
								$data_coding->{$iname}->{$new_re_head_key}->{sentences}->{$_tskey}->{mapping}->{multi_tskey} = $_remap_tskey;
								$data_coding->{$iname}->{$new_re_head_key}->{sentences}->{$_tskey}->{mapping}->{bad_multi_tskey} = $_bad_tskey;
								$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{mapping}->{multi_tskey} = $_remap_tskey;
								$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$_tskey}->{mapping}->{bad_multi_tskey} = $_bad_tskey;
								$codes_dirty->{add_codes} = 1;
							}
						}
					}
				}
				
				delete $topic_txt_chars{$_line_ctr};

				$iname_sent_ct++;
				$counts_href = undef;

			}
			$file_peepchars->{$iname} = $file_peepchars->{$iname} + $iname_chars_ctr;
			$file_peeplines->{$iname} = $file_peeplines->{$iname} + scalar(keys %{$topicbypeeps_txt->{$iname}});

			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{iname_sentence_count} = $iname_sent_ct;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{multi_iname_sentence_count} = scalar(keys %topic_txt);
			$new_data_postparse->{aquad_meta_parse}->{topic_lists}->{$iname}->{$i} = $nctopic;
			$data_postparse->{aquad_meta_parse}->{topic_lists}->{$iname}->{$i} = $topic;
			$new_data_postparse->{aquad_meta_parse}->{topic_lists_uc}->{$iname}->{$topic} = $i;
			$data_postparse->{aquad_meta_parse}->{topic_lists_uc}->{$iname}->{$topic} = $i;

			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{topic} = $topic;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{atx_block} = $new_block;
			$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{tblocks_atx}->{$tkey}->{all_iname_sentence_count} = scalar(keys %topic_txt);
			$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{tblocks_atx}->{$tkey}->{atx_block} = $re_tblock;
			$new_data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{tblocks_atx}->{$tkey}->{topic} = $topic;
			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{mapping}->{remapped_keys} = 1;

		}
		
		if(scalar(keys %topic_txt_chars)) {
			say "[$my_shortform_server_type][$me] tkey[$tkey] something is broke, leftover topic txt keys [".scalar(keys %topic_txt_chars)."] at line[".__LINE__."]";
			die "\tdying to fix\n";
		}

		
		$j++;
		$i++;
	}

	foreach my $iname (keys %{ $file_peeplines }) {
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{file_data}->{total}->{str_chars} = $file_peepchars->{$iname};
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{file_data}->{total}->{words} = $file_inamewords->{$iname};
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{file_data}->{total}->{lines} = $file_peeplines->{$iname};
		$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{file_data}->{average}->{chars_per_word} = $file_peepchars->{$iname} / $file_inamewords->{$iname};
	}

	foreach my $iname (keys %$sentblocs) {
		foreach my $tkey (keys %{ $sentblocs->{$iname} }) {
			my $ikey = uc $iname;
			$blocks->{$ikey}->{$tkey}->{topic} = $extract->{$tkey}->{topic};
			my $str_blk = '';
			foreach my $skey (keys %{ $sentblocs->{$iname}->{$tkey} }) {
				my $val = $sentblocs->{$iname}->{$tkey}->{$skey};
				$str_blk = $str_blk . $val . ". ";
				my $str = trim_line($val);
				$sentblocs->{$iname}->{$tkey}->{$skey} = $str;
			}
			$blocks->{$ikey}->{$tkey}->{block} = $str_blk;
		}
	}

	say "Scrubbed topic ct[".scalar(keys %$extract)."] yielding; wordblock ct[".scalar(keys %{$wordblocs})."] phrasebloc ct[".scalar(keys %{$phraseblocs})."] lines[".scalar(keys %$peeplines)."]" if $trace;
	return $peeplines;

	return 1;
}

sub make_s_cS_file {
	my ($cat,$task_id,$iname,$skip_first,$trace) = @_;
	
	my $detail_trace = 0;
	my $lines = $data_postparse->{post_parse}->{$iname}->{s_cS}->{lines};

	say "[task:$task_id] data for atx file, lines set[".scalar(@$lines)."]" if $trace;
	
	my $file_text = '';
	my $start = 1;
	if(scalar(@$lines)) {
		if(defined $lines->[0]) {
			if($skip_first) {
				say "[task:$task_id] line 0 is filename, skipping [".$lines->[0]."]" if $trace;
			} else {
				$file_text = $lines->[0];
				say "[task:$task_id] line 0 defined, writing start of s_cS file [".$lines->[0]."]" if $trace;
			}
		} elsif(defined $lines->[1]) {
			$file_text = $lines->[1];
			$start = 2;
			say "line 0 NOT defined, but line 1 defined, start write of atx file str at line 1." if $trace;
		} else {
			die "some problem with data index for writing atx file";
		}
	}
	my $ctr = 1;
	for (my $i=$start; $i<scalar(@$lines); $i++) {
		if(!$lines->[$i]) {
			say "[task:$task_id] missing linedata at line[$i]";
			next;
		}
		my $ktr = $ctr;
		if($ctr < 10) {
			$ktr = '    '.$ctr;
		} elsif($ctr < 100) {
			$ktr = '   '.$ctr;
		} elsif($ctr < 1000) {
			$ktr = '  '.$ctr;
		} elsif($ctr < 10000) {
			$ktr = ' '.$ctr;
		}
		if(!$file_text) {
			$file_text = $ktr . $lines->[$i] . " ";
			$ctr++;
			next;
		}
		$file_text = $file_text . "\n" . $ktr . $lines->[$i] . " ";
		$ctr++;
	}
	say "[task:$task_id] made s_cS filedata, with [$ctr] lines" if $trace;

	## add a newline at end to match AQUAD files
	$file_text = $file_text . "\n";

	return $file_text;
}
sub make_atx_file {
	my ($cat,$task_id,$iname,$trace) = @_;
	
	my $detail_trace = 0;
	my $tblocks = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks};
	my $file_text = '';

	my $ctr = 1;
	if(defined $tblocks and scalar(keys %$tblocks)) {
		foreach my $tkey (sort {$a cmp $b} keys %$tblocks) {
			my $topic = $tblocks->{$tkey}->{topic};
			my $block = $tblocks->{$tkey}->{atxblock};
			if(!$topic or !$block) {
				warn ">>>>>> STRCT ERROR making ATX file....missing text at topic[$tkey] [$iname]";
				next;
			}
			if(!$file_text) {
#				$file_text = $topic . ". " . $block;
				my @w = split ' ',$block;			
				if(scalar(@w)) {
					my $text = '';
					my $test = '';
					my $pre_test = $test;
					for (my $i=0; $i<scalar(@w); $i++) {
						if(!$test) {
							$test = $w[$i];
							next;
						}
						$test = $test . " " . $w[$i];
						if(length($test) > $max_line_length) {
#							$lines->[$lctr] = $pre_test;
							if(!$text) {
								$text = "[" . $topic . "]. " . $pre_test;
#								$text = $pre_test;
							} else {
								$text = $text . "\n" . $pre_test;
							}
							$test = $w[$i];
						}
						$pre_test = $test;
					}
					if(!$text) {
						$text = "[" . $topic . "]. " . $test;
					} else {
						$text = $text . "\n" . $test;
					}
					$file_text = $text;
				}
#				$file_text = $ . $test;
				next;
			}
#			$file_text = $file_text . "\n" . $topic . ". " . $block;
#			$file_text = $file_text . "\n" . $topic . ". ";
			my @w = split ' ',$block;
			if(scalar(@w)) {
				my $text = '';
				my $test = '';
				my $pre_test = $test;
				for (my $i=0; $i<scalar(@w); $i++) {
					if(!$test) {
						$test = $w[$i];
#						$test = $file_text . $w[$i];
						next;
					}
					$test = $test . " " . $w[$i];
					if(length($test) > $max_line_length) {
						if(!$text) {
							$text = "[" . $topic . "]. " . $pre_test;
#						$file_text = $file_text . "\n" . $pre_test;
						} else {
							$text = $text . "\n" . $pre_test;
						}
						$test = $w[$i];
					}
					$pre_test = $test;
				}
				if(!$text) {
					$text = "[" . $topic . "]. " . $test;
				} else {
					$text = $text . "\n" . $test;
				}
				$file_text = $file_text . "\n" . $text;
			}
			$ctr++;
		}
	}
	say "[task:$task_id] made ATX filedata, topic ct[$ctr]" if $trace;
#	    atx_txt:
 #     tblocks:
  #      t1:
   #       atxblock:
	return $file_text;
}
sub make_txt_file {
	my ($cat,$task_id,$iname,$trace) = @_;
	
	my $detail_trace = 0;
	my $tblocks = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks};
	my $file_text = '';

	my $ctr = 1;
	if(defined $tblocks and scalar(keys %$tblocks)) {
		my $left_over = '';
		foreach my $tkey (sort {$a cmp $b} keys %$tblocks) {
			my $topic = $tblocks->{$tkey}->{topic};
			my $block = $tblocks->{$tkey}->{atxblock};
			$block =~ s/##COM\d+##\s//gi;
			$block =~ s/\s##COM\d+##//gi;
			if(!$topic or !$block) {
				warn ">>>>>> STRCT ERROR making ATX file....missing text at topic[$tkey] [$iname]";
				next;
			}
			if(!$file_text) {
				my @w = split ' ',$block;			
				if(scalar(@w)) {
					my $text = '';
					my $test = "[" . $topic . "]";
					my $pre_test = $test;
					for (my $i=0; $i<scalar(@w); $i++) {
						if(!$w[$i]) {
							## empty value
							next;
						}
						if(!$test) {
							$test = $w[$i];
							next;
						}
						$test = $test . " " . $w[$i];
						if(length($test) > $max_line_length) {
							if(!$text) {
								$text =  $pre_test;
							} else {
								$text = $text . "\n" . $pre_test;
							}
							$test = $w[$i];
#							$left_over = $w[$i];
						}
						$pre_test = $test;
						$left_over = $test;
					}
					if($text) {
						$file_text = $text;
					}
				}
				next;
			}
			my @w = split ' ',$block;
			if(scalar(@w)) {
				my $text = '';
				my $test = "<" . $topic . ">";
				my $pre_test = $left_over;
				if($left_over) {
					$test = $left_over . " " . $test;
				}
				if(length($test) > $max_line_length) {
					$text = $pre_test;
					$test = "[" . $topic . "]";
				}
				for (my $i=0; $i<scalar(@w); $i++) {
					if(!$w[$i]) {
						## empty value
						next;
					}
					$test = $test . " " . $w[$i];
					if(length($test) > $max_line_length) {
						if(!$text) {
							$text = $pre_test;
						} else {
							$text = $text . "\n" . $pre_test;
						}
						$test = $w[$i];
#						$test = '';
					}
					$pre_test = $test;
					$left_over = $test;
				}
				if($text) {
					$file_text = $file_text . " \n" . $text;
				}
			}
			$ctr++;
		}
		$file_text = $file_text . " " . $left_over;
	}
	say "[task:$task_id] made TXT filedata, topic ct[$ctr]" if $trace;
	return $file_text;
}
sub make_txt2_file {
	my ($cat,$task_id,$iname,$skip_first,$trace) = @_;
	
	my $detail_trace = 0;
	my $lines = $data_postparse->{post_parse}->{$iname}->{s_cS}->{lines};
	my $file_text = '';

	my $start = 1;
	if(scalar(@$lines)) {
		if(defined $lines->[0]) {
			if($skip_first) {
				say "[task:$task_id] line 0 is filename, skipping [".$lines->[0]."]" if $trace;
			} else {
				$file_text = $lines->[0];
				say "[task:$task_id] line 0 defined, writing start of s_cS file [".$lines->[0]."]" if $trace;
			}
		} elsif(defined $lines->[1]) {
			$file_text = $lines->[1];
			$start = 2;
			say "line 0 NOT defined, but line 1 defined, start write of atx file str at line 1." if $trace;
		} else {
			die "some problem with data index for writing atx file";
		}
	}
	my $ctr = 1;
	for (my $i=$start; $i<scalar(@$lines); $i++) {
		if(!$lines->[$i]) {
			say "[task:$task_id] missing linedata at line[$i]";
			next;
		}
		if(!$file_text) {
			$file_text = $lines->[$i] . " ";
			$ctr++;
			next;
		}
		$file_text = $file_text . "\n" . $lines->[$i] . " ";
		$ctr++;
	}
	say "[task:$task_id] made s_cS filedata, with [$ctr] lines" if $trace;

	## add a newline at end to match AQUAD files
	$file_text = $file_text . "\n";

	return $file_text;
}
	
sub mesh_codes {
	my ($cat,$task_id,$sentblocs,$iname,$trace) = @_;
	my $me = "MESH-CODES";
	$me = $me . "][taskid:" . $task_id . "][cat:" . $cat;

	my $mesh_trace = 0;
	my $trace_detail = 0;
	my $trace_code_ct = 0;
	if($iname=~/p0l0/i) {
		$trace_code_ct = 0;
	}
	my $this = 0;
	
#	my @keep_orig_topic = ();
#	my @keep_orig_topic_key = ();
	my $topic_main_codes = $topic_to_code_mapping->{main_codes};
	my $topic_alt_codes = $topic_to_code_mapping->{alt_codes};
	my $topic_sub_codes = $topic_to_code_mapping->{code_sub_links};
#	say "= [$my_shortform_server_type][$task_id][$me]....topic codes [".scalar(@keep_orig_topic)."] sentbloc{".scalar(keys %$sentblocs)."}" if $trace;

	## CHANGES:
	## no extensive pre-coding anymore, i.e. main, alt, and sub codes
	##   may use a text pre-parse coding method, but not multiple code to topic associations
	## method looks for a least one main code copied into *special_words.yml* under PARSE_CODING...don't ask why...
	## codes are added to a code sorter in preference order (sub, alt, main) and then added to POSTPARSE sentences.
	say "= [$my_shortform_server_type][$me] topic mapping hash[$topic_to_code_mapping] code size[".scalar(keys %$topic_to_code_mapping)."]" if $trace;

	my $re_coding = 0;
	my $coding = 0;
	if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks} and scalar(keys %{ $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks} })) {
		say "= [$my_shortform_server_type][$me] iname[$iname]  mesh tblock count[".scalar(keys %{ $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks} })."]" if $trace;
		foreach my $tkey (keys %{ $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks} }) {
			my $s_ct = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{iname_sentence_count};
			my $top = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{topic};
			say "[$my_shortform_server_type][$me] iname[$iname] tkey[$tkey] sent ct[$s_ct] topic[$top]" if $trace;
#			if(!exists $data_coding->{$iname}->{codes}->{topic_coding}->{$top}) {
#				say "[$my_shortform_server_type][$task_id][$me] iname[$iname] tkey[$tkey] no topic coding[$top]" if $trace;
#			}
			my $c = $data_postparse->{aquad_meta_parse}->{topic_lists_uc}->{$iname}->{$top};
			my $top_lc = $data_postparse->{aquad_meta_parse}->{topic_lists}->{$iname}->{$c};

			for (my $i=1; $i<($s_ct+1); $i++) {
				my $tskey = $tkey . "s" . $i;
				my $recoding = 0;
#				say "[$my_shortform_server_type][$task_id][$me] iname[$iname] tskey[$tskey] re_codes ct[".scalar(keys %{$data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{codes}})."]" if $trace;
				if(exists $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{codes} and scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{codes} })) {
					foreach my $cindex (keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{codes} }) {
						$data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes}->{$cindex} = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{codes}->{$cindex};
					}
					say "[$my_shortform_server_type][$task_id][$me] iname[$iname] tskey[$tskey] re_codes ct[".scalar(keys %{$data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{codes}})."]" if $trace_code_ct;
					$recoding = 1;
				}
				if(exists $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{aspects} and scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{aspects} })) {
					foreach my $ikey (keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{aspects} }) {
						$data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{aspects}->{$ikey} = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{aspects}->{$ikey};
					}
				}
				if(exists $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{role} and scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{role} })) {
					foreach my $ikey (keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{role} }) {
						$data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{role}->{$ikey} = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{role}->{$ikey};
					}
				}
				if(exists $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{view} and scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{view} })) {
					foreach my $ikey (keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{view} }) {
						$data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{view}->{$ikey} = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{view}->{$ikey};
					}
				}
#				if(!exists $data_postparse->{aquad_meta_parse}->{topic_coding}->{main_codes}->{$top}) {
#					if(exists $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{main_code}) {
#						$data_postparse->{aquad_meta_parse}->{topic_coding}->{main_codes}->{$top} = $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{main_code};
#					}
#				}
				
				if(!$recoding) {
#					if(exists $data_coding->{$iname}->{codes}->{topic_coding}->{$top}) {
					say "[$my_shortform_server_type][$me] iname[$iname] tskey[$tskey] sorted codes ct[".scalar(keys %{$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}})."]" if $trace_code_ct;
#						if(exists $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{code_qualifiers}) {
#							foreach my $cindex (keys %{ $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{code_qualifiers} }) {
#								my $code = $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{code_qualifiers}->{$cindex};
#								$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}->{$code} = 'q';
#							}
#						}
					## and any SUB codes to code sorter array
					foreach my $top2 (keys %$topic_sub_codes) {
						if($top2=~/^$top$/i) {
							my $tcode = $topic_sub_codes->{$top2};
							$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}->{$tcode} = 'q';
						}
					}
#						if(exists $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{alt_codes}) {
#							foreach my $cindex (keys %{ $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{alt_codes} }) {
#								my $code = $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{alt_codes}->{$cindex};
#								$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}->{$code} = 'a';
#							}
#						}
					## and any ALT codes to code sorter array
					foreach my $top2 (keys %$topic_alt_codes) {
						if($top2=~/^$top$/i) {
							my $tcode = $topic_alt_codes->{$top2};
							$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}->{$tcode} = 'a';
						}
					}

#					if(exists $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{main_code}) {
#							my $code = $data_coding->{$iname}->{codes}->{topic_coding}->{$top}->{main_code};
#						$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}->{$code} = 'm';
#					}

					## if topic does not exist to set at *base* topic code...bark an error
					if(!exists $topic_main_codes->{$top_lc}) {
						say "[$my_shortform_server_type][$task_id][$me] iname[$iname] tskey[$tskey] [$top_lc] does not exist in main codes!! ct[".scalar(keys %{$topic_main_codes})."]" if $trace_code_ct;
					}
					## and any MAIN codes to code sorter array
					if(exists $topic_main_codes->{$top_lc}) {
						my $tcode = $topic_main_codes->{$top_lc};
						$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}->{$tcode} = 'm';
						say "[$my_shortform_server_type][$me] [$iname] tskey[$tskey] [$top_lc] code[$tcode} in main codes, ct[".scalar(keys %{$topic_main_codes})."] sorted[".scalar(keys %{$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}})."]" if $trace_code_ct;
					}

					if(exists $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}) {
						if(exists $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes} and scalar(keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes} })) {
							foreach my $cindex (keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes} }) {
								my $testcode = $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes}->{$cindex};
								$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}->{$testcode} = 's';
								say "[$my_shortform_server_type][$me] [$iname] tskey[$tskey] prev sentence code[$testcode} reload thru code sorter, ct sorted[".scalar(keys %{$data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}})."]" if $trace_code_ct;
								delete $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes}->{$cindex};
							}
						}
					}
					
					my $cctr = 1;

					## loop thru sorted codes and add to topic code list in POSTPARSE
					foreach my $scode (keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes} }) {
						if($data_postparse->{post_parse}->{$iname}->{codes}->{code_sorter}->{$tskey}->{codes}->{$scode}=~/^m$/i) {
							## if a MAIN code, set code in RUNLINKS 
							if(!exists $data_coding->{runlinks}->{add_codes}->{$scode}) {
								$data_coding->{runlinks}->{add_codes}->{$scode} = 1;
								say "[$my_shortform_server_type][$me] iname[$iname] tskey[$tskey] adding new main code [$scode] topic[$top]" if $trace_code_ct;
								if(!exists $codes_dirty->{add_codes} or !$codes_dirty->{add_codes}) {
									$codes_dirty->{add_codes} = 1;
								}
							}
						}
						if(!exists $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey} or !scalar(keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey} })) {
							$data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes}->{1} = $scode;
							$cctr++;
							next;
						}

						if(!exists $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes} or !scalar(keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes} })) {
							$data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes}->{1} = $scode;
							$cctr++;
							next;
						}

#						my $found = 0;
#							my $size = 1;
#							foreach my $testcode (keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes} }) {
#								if($testcode=~/^$scode$/i) {
#									$found = 1;
#								}
#								$size++;
#							}
#							if(!$found) {
								$data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes}->{$cctr} = $scode;	
								say "[$my_shortform_server_type][$me] [$iname] adding new code at tskey[$tskey] ctr[$cctr]  [$scode] topic[$top]" if $trace_code_ct;
#							}
#						}
						$cctr++;
					}
					if($cctr>1) { $codes_dirty->{codes_sorted} = 1; }
						
				}
			}
		}
	}

	## set the iname - showing that prelim coding is done and can displayed for re-coding
	$data_coding->{runlinks}->{name_codes}->{$iname} = 1;
	$codes_dirty->{iname_added_to_codes} = 1;

	return 1;
	
}

sub make_code_list {
	my ($sentence_href,$iname,$taskid,$trace) = @_;
	
	my $s_href = {};
	
	if(exists $data_coding->{runlinks}->{code_tree_base}) {
		$s_href = $data_coding->{runlinks}->{code_tree_base};
		return $s_href;
	}

	foreach my $tskey (keys %$sentence_href) {
		if(exists $sentence_href->{$tskey}->{codes} and scalar(keys %{ $sentence_href->{$tskey}->{codes} })) {
			foreach my $cindex (keys %{ $sentence_href->{$tskey}->{final_codes} }) {
				if($cindex > 100) {
					## not a real code...skip
					next;
				}

				## get codes from possible embedded code tree
				my $codetree = $sentence_href->{$tskey}->{final_codes}->{$cindex};
				my $clayers = &make_code_layers($codetree,$iname,$taskid,$trace);
#				if(scalar(keys %$clayers) > 1) {
#					say"[$me] iname[$iname] clayers > 1...base code[".$clayers->{1}."] 2[".$clayers->{2}."]";
#				}
				foreach my $lindex (keys %$clayers) {
					my $code = $clayers->{$lindex};
					if(!exists $s_href->{$code}) {
						$s_href->{$code} = 0;
					}
					## if code tree contains more than the base code
					## then set the base code to falsy to flag the code
					## as the base of the tree...and stop distance calc of tree elements
					if($lindex > 1) { $s_href->{ $code } = $clayers->{1}; }
				}
			}
		}
	}
	return $s_href;
}
sub make_code_layers {
	my ($code,$not_an_arg,$taskid,$trace) = @_;
	my $layer_arr = {};
	if($code=~/::/) {
		my @arr = split /::/,$code;
		my $ctr = 1;
		my $plus = "";
		my $old = "";
		for (my $i=0; $i<scalar(@arr); $i++) {
			my $code = $arr[$i];
			my $old_form = $code;
			if($plus) {
				$code = $plus . "___" . $arr[$i];
				$old_form = $old . "::" . $arr[$i];
			}
			$temp_code_map_href->{$code} = $old = $old_form;
			$layer_arr->{$ctr} = $plus = $code;
			$ctr++;
		}
	} else {
		$layer_arr->{1} = $code;
		$temp_code_map_href->{$code} = $code;
	}
	return $layer_arr;
}
sub set_code_dispersion {
	my ($cat,$taskid,$sentence_href,$code_list,$iname,$trace) = @_;
	my $me = "CODE-DISP";
	$me = $me . "][taskid:$taskid][cat:$cat";

	my $trace_detail = 0;
	my $trace_cindex = 0;
	my $trace_base = 0;
	my $trace_distance = 0;
	my $trace_dist_updn = 0;
	my $trace_updown = 0;
	my $trace_2x = 0;
	my $trace_stats = 0;

	$data_stats_2x = {};
	$data_stats_updn = {};
#	$data_clustering = {};
	
	if(!exists $data_analysis->{by_iname}) {
		$data_analysis->{by_iname} = {};
	}
	my $analcodes = $data_analysis->{by_iname};
	if(!exists $data_stats->{by_iname}) {
		$data_stats->{by_iname} = {};
	}
#	my $statcodes = $data_stats->{by_iname};
	if(!exists $data_stats_2x->{by_iname}) {
		$data_stats_2x->{by_iname} = {};
	}
	my $statcodes2x = $data_stats_2x->{by_iname};
	if(!exists $data_stats_linkage->{by_iname}) {
		$data_stats_linkage->{by_iname} = {};
	}
	my $statlinks = $data_stats_linkage->{by_iname};
	if(!exists $data_stats_updn->{by_iname}) {
		$data_stats_updn->{by_iname} = {};
	}
	my $statcodes = $data_stats_updn->{by_iname};
	if(!exists $data_clustering->{by_iname}) {
		$data_clustering->{by_iname} = {};
	}
	my $statclusters = $data_clustering->{by_iname};

	## clear existing iname data
	if(exists $analcodes->{$iname}) {
		$analcodes->{$iname} = {};
	}
	if(exists $statcodes2x->{$iname}) {
		$statcodes2x->{$iname} = {};
	}
	if(exists $statlinks->{$iname}) {
		$statlinks->{$iname} = {};
	}
	if(exists $statcodes->{$iname}) {
		$statcodes->{$iname} = {};
	}
	if(exists $statclusters->{$iname}) {
		$statclusters->{$iname} = {};
	}
	if(exists $anal_coding->{by_iname}->{$iname}) {
		$anal_coding->{by_iname}->{$iname} = {};
	}
	if(exists $stats_base_disp->{by_iname}->{$iname}) {
		$stats_base_disp->{by_iname}->{$iname} = {};
	}
	
	my $codes_key = 'final_codes';

	my $sorter = {};
	my $cctr = 0;
#	my $sentence_codes = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey};

	foreach my $tskey (keys %{ $data_coding->{$iname}->{re_codes}->{sentences} }) {
		if($tskey=~/^t(\d+)s(\d+)/i) {
			my $t = $1;
			my $s = $2;
			$sorter->{$t}->{$s} = $tskey;
			$cctr++;
		}
	}
	say "[$me] iname[$iname] post sentence sorter, [$cctr] sentences";

	my @sentences_arr = ();
	my %sentence_ctr = ();
	$cctr = 0;
	foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
		foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
			push @sentences_arr,$sorter->{$tindex}->{$sindex};
			$sentence_ctr{ $sorter->{$tindex}->{$sindex} } = $cctr;
			$cctr++;
		}
	}

	
	my $overlap_thres = 1;
	my $nesting_thres = 7;
	my $short_dist_limit = 3;
	my $mid_dist_limit = 27;
	my $sent_ct_size = 9.55;
	my $word_grp_size = 113;
	
	if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} })) {
		say "[$me] prime codehref error...prime code list is not valid!";
		die "\tdying to fix at[".__LINE__."]\n";
	}
	my $prime_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes};
	say "[$me] prime codes loaded...size[".scalar(keys %$prime_codehref)."]" if $trace;
		
	if(scalar(keys %$prime_codehref)) {
		my $ktr = 0;
		my $low_limit = 1;
		if(exists $post_text_config->{prime_code_count_low_limit} and $post_text_config->{prime_code_count_low_limit}) {
			$low_limit = $post_text_config->{prime_code_count_low_limit};
		}
		my $_sorter = {};
		$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{sentences}->{group_num}->{grp_size} = $sent_ct_size;
		$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{words}->{group_num}->{grp_size} = $word_grp_size;
#		my $big_word_total = 0;
		foreach my $code (keys %$prime_codehref) {
			my $total = 0;
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count}) {
				$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count};
			}
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count}) {
				$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count};
			}
			$_sorter->{$code} = $total;
		}
		say "[$me] prime sorter hash...size[".scalar(keys %$_sorter)."]" if $trace;
		foreach my $code (sort { $_sorter->{$b} <=> $_sorter->{$a} } keys %$_sorter) {
			my $allcount = $_sorter->{$code};
			if($low_limit > $allcount) {
				say " [$me] prime code limiter, PER_code_stats, code[$code] code size too small[".$allcount."]" if $trace_detail;
				next;
			}
			my $base_code = $data_coding->{runlinks}->{code_tree_base}->{$code};
			if(!$base_code) {
				$base_code = $code;
			}
			my $distance = 0;
			my $xero_count = 1;
			my $all_xero_count = 0;
			my $first_found = 0;
			my $index = 0;
			my $sent_ctr = 0;
			my $sent_words = 0;
			foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
				foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
					my $tskey = $sorter->{$tindex}->{$sindex};
					$sent_words = $sent_words + $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{words};
					my $link_xeros = 0;
					$sent_ctr++;

					my $grp_num = $sent_ctr / $sent_ct_size;
					## give NO digits to the right
					if($grp_num=~/([\d]+)(\.[\d]+)/) {
						$grp_num = $1;
						$grp_num++;
					}
					my $wd_grp_num = $sent_words / $word_grp_size;
					## give NO digits to the right
					if($wd_grp_num=~/([\d]+)(\.[\d]+)/) {
						$wd_grp_num = $1;
						$wd_grp_num++;
					}
					my $sentence_codes = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey};
					if(exists $sentence_codes->{ $codes_key } and scalar(keys %{ $sentence_codes->{ $codes_key } })) {
#					if(exists $sentence_href->{$tskey}->{ $codes_key } and scalar(keys %{ $sentence_href->{$tskey}->{ $codes_key } })) {
						my $found = 0;
						my $zero_count = 0;
						foreach my $cindex (keys %{ $sentence_codes->{ $codes_key } }) {
							if($cindex > 100) {
								## not a real code...skip
								next;
							}
							## get codes from possible embedded code tree
#							my $codetree = $sentence_href->{$tskey}->{ $codes_key }->{$cindex};
#							my $clayers = &make_code_layers($codetree,$iname,$taskid,$trace);

							my $_code = $sentence_codes->{ $codes_key }->{$cindex};
							my $_base_code = $data_coding->{runlinks}->{code_tree_base}->{$_code};
							if(!$_base_code) {
								if($_code!~/::/) {
									next;
								}
								my @pts = split "::",$_code;
								if(!scalar(@pts)) {
									die "\t[$me]...what the hell....splitting[$_code] broke at line[".__LINE__."]\n";
								}
								$_base_code = $pts[0];
#								say "[$me] NEW base_code[$base_code] for _code[$_code]";
								$data_coding->{runlinks}->{code_tree_base}->{$_code} = $_base_code;
#								$update_data_coding = 1;
							}
							if($_base_code eq $base_code) {
								$found = 1;
								if(!$first_found) {
									$zero_count++;
									next;
								}
								$zero_count++;
								if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$distance}) {
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$distance} = 0;
								}
								if($xero_count) {
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$distance} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$distance} + 1;
									$link_xeros++;
									$xero_count--;
								}

								## topic clustering
								if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}) {
									$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}->{by_tindex}->{$tindex}->{count} = 0;
								} elsif(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}->{by_tindex}->{$tindex}) {
									$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}->{by_tindex}->{$tindex}->{count} = 0;
								}
								$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}->{by_tindex}->{$tindex}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}->{by_tindex}->{$tindex}->{count} + 1;
								

								say "[$me][$iname][$tskey] Base [$ktr] dist[$distance] fnd[$found]1fnd[$first_found] zeros[$zero_count][$all_xero_count] code[$code]:base[".$_base_code."]c[$cindex:$_code]" if $trace_cindex;
#								next;
							}
							if($ktr > 134) {
#								say "[$me][$iname] Base Disp [$ktr] dist[$distance] found[$found] zeros[$zero_count] codes[$base_code]:base[".$_base_code."]" if $trace;
							}
						}
#						say "[$me][$iname] Base Disp [$ktr] dist[$distance] found[$found] zeros[$zero_count] codes size[".scalar(keys %{ $sentence_href->{$tskey}->{ $codes_key } })."]:[$code]" if $trace;
						if($found) {
							$distance = 1;
							$xero_count = $zero_count;
							$all_xero_count = $all_xero_count + $zero_count;
							if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}) {
								$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{base} = 0;
							}
							$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{base} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{base} + 1;

							## sent group clustering
							if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}) {
								$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count} = 0;
							}
							if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}) {
								$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}->{by_code}->{$code}->{count} = 0;
							}
							## sent group clustering
							if(!$grp_num) {
								die "\n... bad grp num\n";
							}
							my $gg = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}->{by_code}->{$code}->{count};
							$gg++;
#							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count} + 1;
							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count} = $gg;
							
							my $ggg = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count};
							$ggg++;
							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count} = $ggg;
#							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}->{by_code}->{$code}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}->{by_code}->{$code}->{count} + 1;
								
							## word group clustering
							if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}) {
								$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$wd_grp_num}->{count} = 0;
							}
							if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}) {
								$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}->{by_code}->{$code}->{count} = 0;
							}
							## word group clustering
							my $ww = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$wd_grp_num}->{count};
							$ww++;
							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$wd_grp_num}->{count} = $ww;
							my $www = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}->{by_code}->{$code}->{count};
							$www++;
							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}->{by_code}->{$code}->{count} = $www;
#							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$wd_grp_num}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$wd_grp_num}->{count} + 1;
#							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}->{by_code}->{$code}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}->{by_code}->{$code}->{count} + 1;
							
							if($zero_count > 1) {
								if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros}) {
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros} = 0;
								}
								$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros} + $zero_count - 1;
							}
							if(!$first_found) {
								$first_found = 1;
							} else {
								if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}) {
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{base} = 0;
								}
								$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{base} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{base} + 1;
								if($zero_count > 1) {
									if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros}) {
										$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros} = 0;
									}
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros} + $link_xeros - 1;
								}
							}
							say "[$me][$iname][$tskey] Base *[$ktr] fnd[$found]1stfnd[$first_found] zeros[$zero_count][$all_xero_count] wd_grp[$wd_grp_num] code[$code]:base[".$base_code."]" if $trace_base;

						} else {
							if($first_found) {
								$distance++;
							}
						}
					}
					if($grp_num > $stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{sentences}->{group_num}->{max_count}) {
						$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{sentences}->{group_num}->{max_count} = $grp_num;
					}
					if($wd_grp_num > $stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{words}->{group_num}->{max_count}) {
						$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{words}->{group_num}->{max_count} = $wd_grp_num;
					}
				} ## sentences
			} ## topics
			if($all_xero_count) {
				if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{allcount}->{zero}) {
					$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{allcount}->{zero} = 0;
				}
				$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{allcount}->{zero} = $all_xero_count;
			}
			$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{sentences}->{eachs}->{count} = $sent_ctr;
			$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{words}->{total}->{count} = $sent_words;
			
			#		my $text_code = $data_coding->{runlinks}->{code_form_mapping}->{$code};

			my $cktr = 0;
			my $zero_density_ctr = 0;
			my $dist_density_sum = 0;
			my $dist_density_ctr = 0;
			my $short_density_sum = 0;
			my $med_density_sum = 0;
			my $large_density_sum = 0;
			my $short_dist_ctr = 0;
			my $med_dist_ctr = 0;
			my $large_dist_ctr = 0;
			if(exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}) {
				foreach my $dist (keys %{ $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances} }) {
					if($dist=~/^zero$/i) {
						$zero_density_ctr = $zero_density_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{zero};
						next;
					}
					$dist_density_sum = $dist_density_sum + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist} * $dist;
					$dist_density_ctr = $dist_density_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist};
					if($dist < ($short_dist_limit + 1)) {
						$short_density_sum = $short_density_sum + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist} * $dist;
						$short_dist_ctr = $short_dist_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist};
					} elsif($dist < ($mid_dist_limit + 1)) {
						$med_density_sum = $med_density_sum + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist} * $dist;
						$med_dist_ctr = $med_dist_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist};
					}
					if($dist > ($mid_dist_limit)) {
						$large_density_sum = $large_density_sum + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist} * $dist;
						$large_dist_ctr = $large_dist_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist};
					}
					$cktr++;
				}
				my $bases = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{base};
				my $zeros = 0;
				if(exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros}) {
					$zeros = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros};
				}
				my $l_bases = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{base};
				my $l_zeros = 0;
				if(exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros}) {
					$l_zeros = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros};
				}
				if($bases) {
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{modus}->{hit_zeros} = ($zeros + $bases) / $bases;
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{hits}->{base} = $bases;
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{hits}->{zeros} = $zeros;
				}
				if($l_bases) {
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{modus}->{link_zeros} = ($l_zeros + $l_bases) / $l_bases;
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{links}->{base} = $l_bases;
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{links}->{zeros} = $l_zeros;
				}
			}
			
#			$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{zeros} = $zero_density_ctr;
			$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{count} = $dist_density_ctr;
			$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{sum} = $dist_density_sum;
			if($dist_density_ctr>0) {
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean} = $dist_density_sum / $dist_density_ctr;
			}
			if($dist_density_ctr==0) {
				## no distances available
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{count} = 0;
			}
			$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean_narrow} = 0;
			$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{sum} = $short_density_sum;

			if($short_dist_ctr) {
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{count} = $short_dist_ctr;
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean_narrow} = $short_density_sum / $short_dist_ctr;
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{mean} = $short_density_sum / $short_dist_ctr;
			} else {
				if($dist_density_ctr) {
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean_narrow} = $dist_density_sum / $dist_density_ctr;
				}
			}
			if($med_dist_ctr) {
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{medium}->{count} = $med_dist_ctr;
			}
			if($large_dist_ctr) {
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{wide}->{count} = $large_dist_ctr;
			}
			
			$ktr++;
			say "[$me][$iname] Base Disp [$ktr][$cktr] totals(z:ct:sum)[$zero_density_ctr:".$dist_density_ctr.":".$dist_density_sum."]:[$code]" if $trace;

		} ## end of codes loop

		$codes_dirty->{base_dispersion} = 1;
		$codes_dirty->{dispersion} = 1;
	}
			
	return $taskid;
	## skip the other dispersions....too hard, too little value...
			

	my $ktr = 0;
	my $cktr = 0;
	my @code_loop = ();
	my $active_sent_codes = {};
	foreach my $code (keys %$code_list) {
		$ktr++;
		push @code_loop,$code;
		my $distance = 0;
		my $first_found = 0;
		my $index = 0;
		foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
			foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
				my $tskey = $sorter->{$tindex}->{$sindex};
				if(exists $sentence_href->{$tskey}->{ $codes_key } and scalar(keys %{ $sentence_href->{$tskey}->{ $codes_key } })) {
					my $found = 0;
					foreach my $cindex (keys %{ $sentence_href->{$tskey}->{ $codes_key } }) {
						if($cindex > 100) {
							## not a real code...skip
							next;
						}

						## get codes from possible embedded code tree
						my $codetree = $sentence_href->{$tskey}->{ $codes_key }->{$cindex};
						my $clayers = &make_code_layers($codetree,$iname,$taskid,$trace);

						## this code has a base code!
						foreach my $lindex (keys %$clayers) {
							my $testcode = $clayers->{$lindex};
							if($testcode=~/^$code$/i) {
								$found = 1;
								last;
							}
						}
					}
					if($found) {
						if(!exists $active_sent_codes->{$code}) {
							$active_sent_codes->{$code} = [];
							$cktr++;
						}
						my $arr = $active_sent_codes->{$code};
						push @$arr,$tskey;
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_location} = $tskey;
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_count} = $index;
							$index++;
							next;
						}
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} + 1;
						
						## topic clustering
						if(!exists $statclusters->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$tindex}) {
							$statclusters->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$tindex}->{count} = 0;
						}
						$statclusters->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$tindex}->{count} = $statclusters->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$tindex}->{count} + 1;
						my $sent_ind = $sentence_ctr{ $sorter->{$tindex}->{$sindex} };
						if(!exists $statclusters->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sent_ind}) {
							$statclusters->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sent_ind}->{count} = 0;
						}
#						$statclusters->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sent_ind}->{count} = $statclusters->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sent_ind}->{count} + 1;
						$distance = 0;
					}
				}
				if($first_found) {
					$distance++;
				}
				$index++;
			}
		}
		my $stop_pt = 10;
		my $sum = 0; ## first found does not create a initial distance count...start at 1 for actual count
		my $dist_counts = 0;
		my $ktr2 = 0;
		my $short_sum = 0;
		my $med_sum = 0;
		my $large_sum = 0;
		my $t_sum = 0;
		my $total_sum = 0;
		my $short_ct = 0;
		my $med_ct = 0;
		my $large_ct = 0;
		if(exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}) {
			foreach my $dist (keys %{ $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances} }) {
				if(!$sum) { $sum = 1; } ## reset count to one
				$sum = $sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
				$dist_counts = $dist_counts + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
				$t_sum = $t_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
				$total_sum = $total_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
				if($ktr2 < $stop_pt) {
					print "[$me] dispersion [$iname][$ktr2][$code] dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist}."] sum[$sum]" if $trace_distance;
				}
				if($dist < ($short_dist_limit + 1)) {
					$short_ct = $short_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
					$short_sum = $short_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						say "  short ct[$short_ct] short sum[$short_sum]" if $trace_distance;
					}
				} elsif($dist < ($mid_dist_limit + 1)) {
					$med_ct = $med_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
					$med_sum = $med_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						say "  med ct[$med_ct] med sum[$med_sum]" if $trace_distance;
					}
				}
				if($dist > ($mid_dist_limit)) {
					$large_ct = $large_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
					$large_sum = $large_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						say "  large ct[$large_ct] large sum[$large_sum]" if $trace_distance;
					}
				}
				$ktr2++;
			}
			say "[$me][$iname] Disp Calc [$ktr][$cktr] tskey_ct[".scalar(@{ $active_sent_codes->{$code} })."] dist:grps[$ktr2] cts(n:m:l)[$short_ct:$med_ct:$large_ct] sum[$total_sum]:[$code]" if $trace;
		}
		$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{count} = $dist_counts;
		$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{sum} = $total_sum;
		if($dist_counts>0) {
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean} = $total_sum / $dist_counts;
		}
		if($dist_counts==0) {
			## no distances available
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{count} = 0;
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{count} = 1;
#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{sum} = 0;
#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{mean} = 0;
		}
		$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow} = 0;
		
		if($short_ct) {
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{count} = $short_ct;
#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{sum} = $short_sum;
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow} = $short_sum / $short_ct;
		} else {
			if($dist_counts) {
				$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow} = $total_sum / $dist_counts;
			}
		}
		if($med_ct) {
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{count} = $med_ct;
#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{sum} = $med_sum;
#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{mean} = $med_sum / $med_ct;
		}
		if($large_ct) {
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{count} = $large_ct;
#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{sum} = $large_sum;
#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{mean} = $large_sum / $large_ct;
		}
		$codes_dirty->{dispersion} = 1;
	}

	$ktr = 0;
	$cktr = 0;

	return $taskid;
	## skip the other dispersions....too hard, too little value...

	
	
	
	
	## Up-Down dispersion calc
	##
	foreach my $code (keys %$code_list) {
		$ktr++;
		if(!exists $active_sent_codes->{$code}) {
			## nothing set above...skip a'roonie
			next;
		}
		$cktr++;
		my $c_arr = $active_sent_codes->{$code};
		if(!scalar(@$c_arr)) {
			say "[$me][$iname}[$ktr] GO UP - this base code[$code] no arr[".$active_sent_codes->{$code}."] tskey_ct[".scalar(@{ $active_sent_codes->{$code} })."] code arr ct[".scalar(@$c_arr)."]";
			say "\tfix";
			die "\tstop check...\n";
			next;
		}
		my $code_start_tskey = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_location};
		my $code_start_index = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_count};
		my $distance = 0;
		if($ktr > 1000) {
			last;
		}
		my $src_code_ct = 0;
		my $target_code_ct = 0;
		say "[$me][$iname] GO UP for base code[$ktr][$code] start ptr[$code_start_index] start key[$code_start_tskey] s[0] code arr ct[".scalar(@$c_arr)."] sentctr[".scalar(keys %sentence_ctr)."] codeptr[".$sentence_ctr{ $c_arr->[0] }."]" if $trace_updown;
		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
			my $test_code = $code_loop[$cc];
#			if($test_code eq $code) {
#				## same code...skip
#				next;
#			}
			if($code_list->{$code}) {
				## this code has a base code!
				if($code_list->{$test_code}) {
					## the test code also has a base code!
					if($code_list->{$test_code} eq $code_list->{$code}) {
						## same code tree...skip
						next;
					}
				} else {
					if($test_code eq $code_list->{$code}) {
						## base code tree matches open code...skip
						next;
					}
				}
			} else {
				if($code_list->{$test_code}) {
					## the test code has a base code!
					if($code eq $code_list->{$test_code}) {
						## open code matches base of code tree...skip
						next;
					}
				} else {
					if($test_code eq $code) {
						## same code...skip
						next;
					}
				}
			}
			my $s = 0;
			my $temp_tskey = $c_arr->[$s];
			my $code_ptr = $sentence_ctr{ $temp_tskey };
			$s++;
			my $src_ctr = 0;
			my $target_ctr = 0;
			for (my $ss=0; $ss<scalar(@sentences_arr); $ss++) {
				my $tskey = $sentences_arr[$ss];
				if($ss < $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						$distance = $code_ptr - $ss;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$distance} + 1;
						$distance = 0;
						$target_ctr++;
					}
				} elsif($ss == $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero_2x}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero_2x} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero_2x} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero_2x} + 1;
					} else {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero} + 1;
					}
					$distance = 0;
					$src_ctr++;
					if($s == scalar(@$c_arr)) {
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF src tskeys, same code ptr[$code_ptr] src code ct[$s]" if $trace;
						$s++;
					} else {
						my $temp_tskey = $c_arr->[$s];
						if(!$temp_tskey) {
							die "\t dying to fix bad temp tskey\n";
						}
						$code_ptr = $sentence_ctr{ $temp_tskey };
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] temp tskey[$temp_tskey] code ptr[$code_ptr] src code ct[$s] size[".scalar(@$c_arr)."] [".$sentence_ctr{ $c_arr->[$s] }."]" if $trace;
						$s++;
					}
				} else {
					if($s > scalar(@$c_arr)) {
						## no more code value in stack
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF test of [$test_code] code ptr[$code_ptr] src code ct[$s]" if $trace;
						last;
					}
					say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code] code out of sequence [$ss] ptr[$code_ptr] at [$tskey]";
					die "\tdie to fix\n";
				}
			}
			if($target_ctr) {
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{counts}->{first} = $src_ctr;
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{counts}->{second_up} = $target_ctr;
			}
			$src_code_ct = $src_ctr;
		}
		$distance = 0;
		my $top_index = scalar(@$c_arr) - 1;
		say "[$me][$iname] GO DOWN for base code[$ktr][$code] start key[".$c_arr->[$top_index]."] top s[$top_index] code arr ct[".scalar(@$c_arr)."] codeptr[".$sentence_ctr{ $c_arr->[$top_index] }."]" if $trace_updown;
		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
			my $test_code = $code_loop[$cc];
#			if($test_code eq $code) {
#				## same code...skip
#				next;
#			}
			if($code_list->{$code}) {
				## this code has a base code!
				if($code_list->{$test_code}) {
					## the test code also has a base code!
					if($code_list->{$test_code} eq $code_list->{$code}) {
						## same code tree...skip
						next;
					}
				} else {
					if($test_code eq $code_list->{$code}) {
						## base code tree matches open code...skip
						next;
					}
				}
			} else {
				if($code_list->{$test_code}) {
					## the test code has a base code!
					if($code eq $code_list->{$test_code}) {
						## open code matches base of code tree...skip
						next;
					}
				} else {
					if($test_code eq $code) {
						## same code...skip
						next;
					}
				}
			}
			my $s = scalar(@$c_arr) - 1;
			my $temp_tskey = $c_arr->[$s];
			my $code_ptr = $sentence_ctr{ $temp_tskey };
			$s--;
			my $target_ctr = 0;
			my $top_sent = scalar(@sentences_arr) - 1;
			for (my $ss=$top_sent; $ss>=0; $ss--) {
				my $tskey = $sentences_arr[$ss];
				if($ss > $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						$distance = $ss - $code_ptr;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} + 1;
						$distance = 0;
						$target_ctr++;
					}
				} elsif($ss == $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero_2x}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero_2x} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero_2x} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero_2x} + 1;
					} else {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero} + 1;
					}
					$distance = 0;
					if($s < 0) {
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF src tskeys, same code ptr[$code_ptr] src code ct[$s]" if $trace;
					} else {
						my $temp_tskey = $c_arr->[$s];
						if(!$temp_tskey) {
							die "\t dying to fix bad temp tskey\n";
						}
						$code_ptr = $sentence_ctr{ $temp_tskey };
						$s--;
					}
				} else {
					if($s < 0) {
						## no more code value in stack
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF test of [$test_code] code ptr[$code_ptr] src code ct[$s]" if $trace;
						last;
					}
					say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code] code out of sequence [$ss] ptr[$code_ptr] at [$tskey]";
					die "\tdie to fix\n";
				}
			}
			if($target_ctr) {
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{counts}->{first} = $src_code_ct;
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{counts}->{second_dn} = $target_ctr;
				$target_code_ct = $target_ctr;
			}
		}
		say "[$me][$iname] --Up/Down ctr[$ktr], MAKE STATS for[$code] src_code ct[".scalar(@$c_arr)."] targetcode ct[$target_code_ct]" if $trace;
		my $tcktr = 0;
		my $top_code = 0;
		my $top_ktr = 0;
		my $top_ct = 0;
		my $top_sum = 0;
		my $top_short_ct = 0;
		my $top_med_ct = 0;
		my $top_large_ct = 0;
		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
			my $test_code = $code_loop[$cc];
#			if($test_code eq $code) {
#				## same code...skip
#				next;
#			}
			if($code_list->{$code}) {
				## this code has a base code!
				if($code_list->{$test_code}) {
					## the test code also has a base code!
					if($code_list->{$test_code} eq $code_list->{$code}) {
						## same code tree...skip
						next;
					}
				} else {
					if($test_code eq $code_list->{$code}) {
						## base code tree matches open code...skip
						next;
					}
				}
			} else {
				if($code_list->{$test_code}) {
					## the test code has a base code!
					if($code eq $code_list->{$test_code}) {
						## open code matches base of code tree...skip
						next;
					}
				} else {
					if($test_code eq $code) {
						## same code...skip
						next;
					}
				}
			}
			my $short_dist_limit2 = 27;
			my $mid_dist_limit2 = 81;
			my $stop_pt = 3;
			my $ktr2 = 0;
			my $match_ct = 0;
			my $no_match_ct = 0;
			my $count2 = 0; ## found creates an initial distance count
			my $sum2 = 0; ## found creates an initial distance count
			my $short_sum2 = 0;
			my $med_sum2 = 0;
			my $large_sum2 = 0;
			my $short_ct2 = 0;
			my $med_ct2 = 0;
			my $large_ct2 = 0;
			if(exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}) {
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up} }) {
					if($dist eq 'zero_2x') {
						$match_ct = $match_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						next;
					}
					if($dist eq 'zero') {
						$no_match_ct = $match_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						next;
					}
					$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
					$sum2 = $sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						print "[$me] [$iname] dispersion-UP [$code] dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist}."] sum[$sum2] [$test_code]" if $trace_dist_updn;
					}
					if($dist < ($short_dist_limit2 + 1)) {
						$short_ct2 = $short_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						$short_sum2 = $short_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct2] short sum[$short_sum2]" if $trace_dist_updn;
						}
					} elsif($dist < ($mid_dist_limit2 + 1)) {
						$med_ct2 = $med_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						$med_sum2 = $med_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct2] med sum[$med_sum2]" if $trace_dist_updn;
						}
					}
					if($dist > ($mid_dist_limit2)) {
						$large_ct2 = $large_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						$large_sum2 = $large_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct2] large sum[$large_sum2]" if $trace_dist_updn;
						}
					}
					$ktr2++;
				}
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down} }) {
					if($dist eq 'zero_2x') {
						$match_ct = $match_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						next;
					}
					if($dist eq 'zero') {
						$no_match_ct = $match_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						next;
					}
					$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
					$sum2 = $sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						print "[$me] [$iname] dispersion-dn [$code] dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist}."] sum[$sum2] [$test_code]" if $trace_dist_updn;
					}
					if($dist < ($short_dist_limit2 + 1)) {
						$short_ct2 = $short_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						$short_sum2 = $short_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct2] short sum[$short_sum2]" if $trace_dist_updn;
						}
					} elsif($dist < ($mid_dist_limit2 + 1)) {
						$med_ct2 = $med_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						$med_sum2 = $med_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct2] med sum[$med_sum2]" if $trace_dist_updn;
						}
					}
					if($dist > ($mid_dist_limit2)) {
						$large_ct2 = $large_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						$large_sum2 = $large_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct2] large sum[$large_sum2]" if $trace_dist_updn;
						}
					}
					$ktr2++;
				}
				say "[$me] [$iname] --Disp-UpDn Stats [$code] dist grps[$ktr2] dist counts[$count2] dist_sum[$sum2] cts(n:m:l)[$short_ct2:$med_ct2:$large_ct2] 2[$test_code]" if $trace_dist_updn;
				if(!$tcktr) {
					say "[$me][$iname][$ktr][$cktr] 1st Disp-UpDn  dist: grps[$ktr2] cts[$count2] sum[$sum2] cts(n:m:l)[$short_ct2:$med_ct2:$large_ct2]:[$code] 2[$test_code]" if $trace;
				}
			}
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{count} = 0;
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{sum} = $sum2;
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{mean} = 0;
			if($count2) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{count} = $count2;
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{mean} = $sum2 / $count2;
			}
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{match_count} = $match_ct;
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{no_match_count} = $no_match_ct;
			if($match_ct) {
				my $per = 10 * ($match_ct / ($match_ct + $no_match_ct));
				my $per2 = 10 * ($match_ct / $count2);
				if($per2=~/(\d+)\.*([\d]*)/) {
					 if($1 > $overlap_thres) {
						$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_overlap} = $1;
					 }
				}
				if($per=~/(\d+)\.*([\d]*)/) {
					 if($1 >= $nesting_thres and $1 < 10) {
						$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_partial_nesting_first_in_second} = $1;
					 }
					 if($1 == 10) {
						$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_complete_nesting_first_in_second} = $1;
						my $size = 1;
						if(exists $statclusters->{$iname}->{re_codes}->{nesting}->{complete}->{$code}) {
							$size = scalar(keys %{ $statclusters->{$iname}->{re_codes}->{nesting}->{complete}->{$code} });
						}
						$statclusters->{$iname}->{re_codes}->{nesting}->{complete}->{$code}->{$size}->{within} = $test_code;
						$statclusters->{$iname}->{re_codes}->{nesting}->{complete}->{$code}->{$size}->{count} = $match_ct;
					 }				 
				}
				if($match_ct == $count2) {
					$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_complete_nesting_second_in_first} = 10;
					my $size = 1;
					if(exists $statclusters->{$iname}->{re_codes}->{nesting}->{complete}->{$test_code}) {
						$size = scalar(keys %{ $statclusters->{$iname}->{re_codes}->{nesting}->{complete}->{$test_code} });
					}
					$statclusters->{$iname}->{re_codes}->{nesting}->{complete}->{$test_code}->{$size}->{within} = $code;
					$statclusters->{$iname}->{re_codes}->{nesting}->{complete}->{$test_code}->{$size}->{count} = $match_ct;
				}
			}
			if($short_ct2) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{narrow}->{count} = $short_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{narrow}->{sum} = $short_sum2;
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{narrow}->{mean} = $short_sum2 / $short_ct2;
			}
			if($med_ct2) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{medium}->{count} = $med_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{medium}->{sum} = $med_sum2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{medium}->{mean} = $med_sum2 / $med_ct2;
			}
			if($large_ct2) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{wide}->{count} = $large_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{wide}->{sum} = $large_sum2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{wide}->{mean} = $large_sum2 / $large_ct2;
			}
			$tcktr++;
			if($top_ktr < $ktr2) {
				$top_code = $test_code;
				$top_ktr = $ktr2;
				$top_ct = $count2;
				$top_sum = $sum2;
				$top_short_ct = $short_ct2;
				$top_med_ct = $med_ct2;
				$top_large_ct = $large_ct2;
			}
		}
		say "[$me][$iname][$ktr][$cktr] TOP Disp-UpDn [$top_ktr][$tcktr] dist:grps[$top_ct] sum[$top_sum] cts(n:m:l)[$top_short_ct:$top_med_ct:$top_large_ct]:[$code] 2[$top_code]" if $trace;
#		say "[$me][$iname] Dispersion Stat Calc [$ktr] dist:grps[$ktr2] sum[$total_sum] cts(n:m:l)[$short_ct:$med_ct:$large_ct]:[$code]" if $trace;
	}

	## 2x dispersion
	$ktr = 0;
	$cktr = 0;
	my $total_short = 0;
	my $total_med = 0;
	my $total_large = 0;
	foreach my $code (keys %$code_list) {
		$ktr++;
		if(!exists $active_sent_codes->{$code}) {
			## nothing set above...skip a'roonie
			next;
		}
		$cktr++;
		my $c_arr = $active_sent_codes->{$code};
		if(!scalar(@$c_arr)) {
			say "[$me][$iname}[$ktr] 2x Disp - this base code[$code] no arr[".$active_sent_codes->{$code}."] tskey_ct[".scalar(@{ $active_sent_codes->{$code} })."] code arr ct[".scalar(@$c_arr)."]";
			say "\tfix";
			die "\tstop check...\n";
			next;
		}
		my $distance = 0;
		my $distance_src = 0;
		my $double_hit = 2;
		my $index = 0;
		if($ktr > 1000) {
			last;
		}
		my $src_code_ct = 0;
		my $ktr2 = 0;
		say "[$me] iname[$iname} 2X Disp for base code[$ktr][$code] s[0] code arr ct[".scalar(@$c_arr)."] codeptr[".$sentence_ctr{ $c_arr->[0] }."]" if $trace_2x;
		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
			my $test_code = $code_loop[$cc];
			
			## check for whether codes match singular codes or code trees
			if($code_list->{$code}) {
				## this code has a base code!
				if($code_list->{$test_code}) {
					## the test code also has a base code!
					if($code_list->{$test_code} eq $code_list->{$code}) {
						## same code tree...skip
						next;
					}
				} else {
					if($test_code eq $code_list->{$code}) {
						## base code tree matches open code...skip
						next;
					}
				}
			} else {
				if($code_list->{$test_code}) {
					## the test code has a base code!
					if($code eq $code_list->{$test_code}) {
						## open code matches base of code tree...skip
						next;
					}
				} else {
					if($test_code eq $code) {
						## same code...skip
						next;
					}
				}
			}
			my $s = 0;
			my $first_found = 0;
			my $temp_tskey = $c_arr->[$s];
			my $code_ptr = $sentence_ctr{ $temp_tskey };
			$s++;
			my $src_ctr = 0;
			my $target_ctr = 0;
			for (my $ss=0; $ss<scalar(@sentences_arr); $ss++) {
				my $tskey = $sentences_arr[$ss];
				if($ss < $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found and $s == 1) {
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
							$index++;
							say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance] ss<ptr (1-1), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
							next;
						}
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss < ptr (1-2), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} elsif($found) {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] ss < ptr (2), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} elsif($s > 1) {
						$distance++;
						$distance_src++;
					} else {
						if($first_found) {
							$distance++;
						}
					}
#					say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] ss < ptr seq, ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
				} elsif($ss == $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found and $s == 1) {
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
							$distance_src = 1;
							if($s == scalar(@$c_arr)) {
								$distance_src = 0;
#							$s++;
							} else {
								my $temp_tskey = $c_arr->[$s];
								if(!$temp_tskey) {
									die "\t dying to fix bad temp tskey\n";
								}
								$code_ptr = $sentence_ctr{ $temp_tskey };
#								say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] temp tskey[$temp_tskey] code ptr[$code_ptr] src code ct[$s] size[".scalar(@$c_arr)."] [".$sentence_ctr{ $c_arr->[$s] }."]" if $trace;
							}
							$s++;
							next;
						}
#						my $double_hit = 2;
						if($s == scalar(@$c_arr)) {
							$distance_src = 0;
						} else {
							my $temp_tskey = $c_arr->[$s];
							if(!$temp_tskey) {
								die "\t dying to fix bad temp tskey\n";
							}
							$code_ptr = $sentence_ctr{ $temp_tskey };
						}
						$s++;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + $double_hit;
						## (1)
						say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss==ptr (1), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} elsif($found) {
						if($s == scalar(@$c_arr)) {
							$distance_src = 0;
						} else {
							my $temp_tskey = $c_arr->[$s];
							if(!$temp_tskey) {
								die "\t dying to fix bad temp tskey\n";
							}
							$code_ptr = $sentence_ctr{ $temp_tskey };
						}
						$s++;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + $double_hit;
						## (2)
						say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss==ptr (2), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} elsif($s > 1) {
						## been to first ptr
						$distance_src = 1;
						if($s == scalar(@$c_arr)) {
							$distance_src = 0;
						} else {
							my $temp_tskey = $c_arr->[$s];
							if(!$temp_tskey) {
								die "\t dying to fix bad temp tskey\n";
							}
							$code_ptr = $sentence_ctr{ $temp_tskey };
						}
						$s++;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						## (3)
						print "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss==ptr (3), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						if($distance_src) {
							say "" if $trace_2x;
						} else {
							say "-end" if $trace_2x;
						}
						$distance = 1;
					} else { ## case is s==1, no found
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
							$distance_src = 1;
							if($s == scalar(@$c_arr)) {
								$distance_src = 0;
							} else {
								my $temp_tskey = $c_arr->[$s];
								if(!$temp_tskey) {
									die "\t dying to fix bad temp tskey\n";
								}
								$code_ptr = $sentence_ctr{ $temp_tskey };
							}
							$s++;
							## (4-1)
							say "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance] ss==ptr (4-1), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
							next;
						}
						$distance_src++;
						if($s == scalar(@$c_arr)) {
							$distance_src = 0;
						} else {
							my $temp_tskey = $c_arr->[$s];
							if(!$temp_tskey) {
								die "\t dying to fix bad temp tskey\n";
							}
							$code_ptr = $sentence_ctr{ $temp_tskey };
						}
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						$s++;
						$distance++;
						say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss==ptr (4), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
					}
#					say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] ss == ptr seq, ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]";

				} else {
					## no more src codes in sentences field
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						## found (fd)
						say "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss > ptr (fd), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} else {
						$distance++;
						## (+)
#						say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][+] ss > ptr (+), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
					}
				}
			}
			my $short_dist_limit2 = 3;
			my $mid_dist_limit2 = 27;
			my $stop_pt = 1;
			my $match_ct = 0;
			my $count2 = 0;
			my $sum2 = 0;
			my $short_sum2 = 0;
			my $med_sum2 = 0;
			my $large_sum2 = 0;
			my $short_ct2 = 0;
			my $med_ct2 = 0;
			my $large_ct2 = 0;
			if(exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}) {
				say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] loop *two* values" if $trace_2x;
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two} }) {
					$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist};
					$sum2 = $sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						print "[$me] [$iname][$ktr][$code][$test_code] 2x stats, dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist}."] ct[$count2]" if $trace_stats;
					}
					if($dist < ($short_dist_limit2 + 1)) {
						$short_ct2 = $short_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist};
						$short_sum2 = $short_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct2] short sum[$short_sum2]" if $trace_stats;
						}
					} elsif($dist < ($mid_dist_limit2 + 1)) {
						$med_ct2 = $med_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist};
						$med_sum2 = $med_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct2] med sum[$med_sum2]" if $trace_stats;
						}
					}
					if($dist > ($mid_dist_limit2)) {
						$large_ct2 = $large_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist};
						$large_sum2 = $large_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct2] large sum[$large_sum2]" if $trace_stats;
						}
					}
					$ktr2++;
				}
				say "[$me][$iname][$ktr] Disp-2x Stat Calc dist grps[$ktr2] dist counts[$count2] dist_sum[$sum2] cts(n:m:l)[$short_ct2:$med_ct2:$large_ct2] 1[$code] 2[$test_code] " if $trace_stats;
			}
			if($count2 > ($short_ct2 + $med_ct2 + $large_ct2 + 1)) {
				say "\t\t2x Counts BROKE! total[$count2] != short[$short_ct2] + med[$med_ct2] + large[$large_ct2] + 1";
			}
			$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{total}->{count} = $count2;
			$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{total}->{sum} = $sum2;
			$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{narrow}->{count} = 0;
			if($count2) {
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{total}->{mean} = $sum2 / $count2;
			}
			if($short_ct2) {
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{narrow}->{count} = $short_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{narrow}->{sum} = $short_sum2;
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{narrow}->{mean} = $short_sum2 / $short_ct2;
			}
			if($med_ct2) {
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{medium}->{count} = $med_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{medium}->{sum} = $med_sum2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{medium}->{mean} = $med_sum2 / $med_ct2;
			}
			if($large_ct2) {
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{wide}->{count} = $large_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{wide}->{sum} = $large_sum2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{wide}->{mean} = $large_sum2 / $large_ct2;
			}

			$total_short = $total_short + $short_ct2;
			$total_med = $total_med + $med_ct2;
			$total_large = $total_large + $large_ct2;

		}
		say "[$me][$iname}[$ktr][$cktr] 2X Disp, total cts(n:m:l)[$total_short:$total_med:$total_large] ctrs, 1st arr[".scalar(@$c_arr)."] 2nd codes[$ktr2] base code[$code]" if $trace;
	}

	return $taskid;
}
sub set_code_dispersion_multi {
	my ($cat,$taskid,$file_parse_key,$code_list,$trace) = @_;
	my $me = "DISPER-MULTI";
	$me = $me . "][taskid:$taskid][cat:$cat";

	my $trace_detail = 0;
	my $trace_updown = 0;
	my $trace_2x = 0;
	my $trace_stats = 1;
	
	if(!exists $data_analysis->{by_iname}) {
		$data_analysis->{by_iname} = {};
	}
	my $analcodes = $data_analysis->{by_iname};
	if(!exists $data_stats->{by_iname}) {
		$data_stats->{by_iname} = {};
	}
#	my $statcodes = $data_stats->{by_iname};
	if(!exists $data_stats_2x->{by_iname}) {
		$data_stats_2x->{by_iname} = {};
	}
	my $statcodes2x = $data_stats_2x->{by_iname};
	if(!exists $data_stats_linkage->{by_iname}) {
		$data_stats_linkage->{by_iname} = {};
	}
	my $statlinks = $data_stats_linkage->{by_iname};
	if(!exists $data_stats_updn->{by_iname}) {
		$data_stats_updn->{by_iname} = {};
	}
	my $statcodes = $data_stats_updn->{by_iname};
	if(!exists $data_clustering->{by_iname}) {
		$data_clustering->{by_iname} = {};
	}
	my $statclusters = $data_clustering->{by_iname};

	my $codes_key = 'final_codes';

	my $sorter = {};
	my $iname_list = {};
	my $cctr = 0;
	if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}) {
		say "  [$my_shortform_server_type][$me] file_key[$file_parse_key] ....sentence list does not exist under *parse_multi_struct* " if $trace;
		die "Not right....[".__LINE__."]\n";
	}
	foreach my $tskey (keys %{ $data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct} }) {
		my $tskey_remap = $data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$tskey}->{tskey_map};
		my $iname = $data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$tskey}->{iname};
		if($tskey=~/^t(\d+)s(\d+)/i) {
			my $t = $1;
			my $s = $2;
			$sorter->{$t}->{$s}->{key} = $tskey;
			## the remap may not be necessary
			$sorter->{$t}->{$s}->{rekey} = $tskey_remap;
			$sorter->{$t}->{$s}->{iname} = $iname;
#			$sorter->{$t}->{$s}->{file_parse_key} = $file_parse_key;
			$cctr++;
		}
		$iname_list->{$iname} = 1;
	}
	say "[$me] file_key[$file_parse_key] post sentence sorter, [$cctr] sentences";

	## clear arrays of iname keyed values
	foreach my $_iname (keys %{ $iname_list }) {
		## clear existing iname data
		if(exists $anal_coding->{by_iname}->{$_iname}) {
			$anal_coding->{by_iname}->{$_iname} = {};
		}
		if(exists $stats_base_disp->{by_iname}->{$_iname}) {
			$stats_base_disp->{by_iname}->{$_iname} = {};
		}
#		if(exists $analcodes->{$_iname}) {
#			$analcodes->{$_iname} = {};
#		}
#		if(exists $statcodes2x->{$_iname}) {
#			$statcodes2x->{$_iname} = {};
#		}
#		if(exists $statlinks->{$_iname}) {
#			$statlinks->{$_iname} = {};
#		}
#		if(exists $statcodes->{$_iname}) {
#			$statcodes->{$_iname} = {};
#		}
#		if(exists $statclusters->{$_iname}) {
#			$statclusters->{$_iname} = {};
#		}
	}

	my @sentences_arr = ();
	my %sentence_ctr = ();
	$cctr = 0;
	foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
		foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
			push @sentences_arr,$sorter->{$tindex}->{$sindex}->{key};
			$sentence_ctr{ $sorter->{$tindex}->{$sindex}->{key} } = $cctr;
			$cctr++;
		}
	}

	my $overlap_thres = 1;
	my $nesting_thres = 7;
	my $short_dist_limit = 3;
	my $mid_dist_limit = 27;
	my $sent_ct_size = 9.55;
	my $word_grp_size = 113;

	## set initial clustering parameters
	foreach my $_iname (keys %{ $iname_list }) {
		$stats_base_disp->{by_iname}->{$_iname}->{clustering}->{info}->{sentences}->{group_num}->{grp_size} = $sent_ct_size;
		$stats_base_disp->{by_iname}->{$_iname}->{clustering}->{info}->{words}->{group_num}->{grp_size} = $word_grp_size;
	}
	
	if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} })) {
		say "[$me] prime codehref error...prime code list is not valid!";
		die "\tdying to fix at[".__LINE__."]\n";
	}
	my $prime_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes};
	say "[$me] prime codes loaded...size[".scalar(keys %$prime_codehref)."]" if $trace;
		

	if(scalar(keys %$prime_codehref)) {
		my $ktr = 0;
		my $low_limit = 1;
		if(exists $post_text_config->{prime_code_count_low_limit} and $post_text_config->{prime_code_count_low_limit}) {
			$low_limit = $post_text_config->{prime_code_count_low_limit};
		}
		my $_sorter = {};
		foreach my $code (keys %$prime_codehref) {
			my $total = 0;
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count}) {
				$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count};
			}
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count}) {
				$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count};
			}
			$_sorter->{$code} = $total;
		}
		say "[$me] prime sorter hash...size[".scalar(keys %$_sorter)."]" if $trace;
		foreach my $code (sort { $_sorter->{$b} <=> $_sorter->{$a} } keys %$_sorter) {
			my $allcount = $_sorter->{$code};
			if($low_limit > $allcount) {
				say " [$me] prime code limiter, PER_code_stats, code[$code] code size too small[".$allcount."]";
				next;
			}
			my $base_code = $data_coding->{runlinks}->{code_tree_base}->{$code};
			if(!$base_code) {
				$base_code = $code;
			}
			my $distance = 0;
			my $xero_count = 1;
			my $first_found = 0;
			my $index = 0;
			my $sent_ctr = 0;
			my $sent_words = 0;
			my $all_xero_count = 0;
			my $all_xero_count_href = {};
			my $sent_ctr_href = {};
			my $sent_words_href = {};
			
			foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
				foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
					my $tskey = $sorter->{$tindex}->{$sindex}->{key};
					my $tskey_re = $sorter->{$tindex}->{$sindex}->{rekey};
					my $iname = $data_postparse->{parse_multi_struct}->{multi_txt}->{$file_parse_key}->{sentence_struct}->{$tskey}->{iname};
					$sent_words = $sent_words + $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey_re}->{counts}->{words};
					my $link_xeros = 0;
					$sent_ctr++;

					my $grp_num = $sent_ctr / $sent_ct_size;
					## give NO digits to the right
					if($grp_num=~/([\d]+)(\.[\d]+)/) {
						$grp_num = $1;
						$grp_num++;
					}
					my $wd_grp_num = $sent_words / $word_grp_size;
					## give NO digits to the right
					if($wd_grp_num=~/([\d]+)(\.[\d]+)/) {
						$wd_grp_num = $1;
						$wd_grp_num++;
					}

					if(!exists $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey_re}) {
						say "[$my_shortform_server_type][$me] iname [$iname] tskey_re[$tskey_re] tskey[$tskey]....codes for sentence list does not exist " if $trace;
						next;
	#					die "Not right....line[".__LINE__."]\n";
					}
					my $sentence_codes = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey_re};
					if(exists $sentence_codes->{ $codes_key } and scalar(keys %{ $sentence_codes->{ $codes_key } })) {
#					if(exists $sentence_href->{$tskey}->{ $codes_key } and scalar(keys %{ $sentence_href->{$tskey}->{ $codes_key } })) {
						my $found = 0;
						my $zero_count = 0;
						foreach my $cindex (keys %{ $sentence_codes->{ $codes_key } }) {
							if($cindex > 100) {
								## not a real code...skip
								next;
							}

							my $_code = $sentence_codes->{ $codes_key }->{$cindex};
							my $_base_code = $data_coding->{runlinks}->{code_tree_base}->{$_code};
							if(!$_base_code) {
								if($_code!~/::/) {
									next;
								}
								my @pts = split "::",$_code;
								if(!scalar(@pts)) {
									die "\t[$me]...what the hell....splitting[$_code] broke at line[".__LINE__."]\n";
								}
								$_base_code = $pts[0];
#								say "[$me] NEW base_code[$base_code] for _code[$_code]";
								$data_coding->{runlinks}->{code_tree_base}->{$_code} = $_base_code;
#								$update_data_coding = 1;
							}
							if($_base_code eq $base_code) {
								$found = 1;
								if(!$first_found) {
									$zero_count++;
									next;
								}
								$zero_count++;
								if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$distance}) {
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$distance} = 0;
								}
								if($xero_count) {
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$distance} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$distance} + 1;
									$link_xeros++;
									$xero_count--;
								}

								## topic clustering
								if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}) {
									$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}->{by_tindex}->{$tindex}->{count} = 0;
								}
								$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}->{by_tindex}->{$tindex}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_topic}->{$code}->{by_tindex}->{$tindex}->{count} + 1;
								
								## sent group clustering
								if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}) {
									$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count} = 0;
								}
								if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}) {
									$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}->{by_code}->{$code}->{count} = 0;
								}
								
								## word group clustering
								if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}) {
									$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$wd_grp_num}->{count} = 0;
								}
								if(!exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}) {
									$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}->{by_code}->{$code}->{count} = 0;
								}

								say "[$me][$iname][$tskey] Base *[$ktr] dist[$distance] fnd[$found]1fnd[$first_found] zeros[$zero_count][$all_xero_count] code[$code]:base[".$_base_code."]c[$cindex:$_code]" if $trace;
#								next;
							}
#							if($ktr > 134) {
#								say "[$me][$iname] Base Disp [$ktr] dist[$distance] found[$found] zeros[$zero_count] codes[$base_code]:base[".$_base_code."]" if $trace;
#							}
						}
#						say "[$me][$iname] Base Disp [$ktr] dist[$distance] found[$found] zeros[$zero_count] codes size[".scalar(keys %{ $sentence_href->{$tskey}->{ $codes_key } })."]:[$code]" if $trace;
						if($found) {
							$distance = 1;
							$xero_count = $zero_count;
							$all_xero_count = $all_xero_count + $zero_count;
							if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}) {
								$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{base} = 0;
							}
							$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{base} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{base} + 1;

							## sent group clustering
							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_sentence_grp}->{$grp_num}->{count} + 1;
							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}->{by_code}->{$code}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_sentence_grp}->{$grp_num}->{by_code}->{$code}->{count} + 1;
							## word group clustering
							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$wd_grp_num}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$wd_grp_num}->{count} + 1;
							$stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}->{by_code}->{$code}->{count} = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_word_grp}->{$wd_grp_num}->{by_code}->{$code}->{count} + 1;
							
							if($zero_count > 1) {
								if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros}) {
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros} = 0;
								}
								$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros} + $zero_count - 1;
							}
							if(!$first_found) {
								$first_found = 1;
							} else {
								if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}) {
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{base} = 0;
								}
								$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{base} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{base} + 1;
								if($zero_count > 1) {
									if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros}) {
										$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros} = 0;
									}
									$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros} = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros} + $link_xeros - 1;
								}
							}
							$all_xero_count_href->{$iname} = $all_xero_count;
							$sent_ctr_href->{$iname} = $sent_ctr;
							$sent_words_href->{$iname} = $sent_words;

						} else {
							if($first_found) {
								$distance++;
							}
						}
					}
					if($grp_num > $stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{sentences}->{group_num}->{max_count}) {
						$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{sentences}->{group_num}->{max_count} = $grp_num;
					}
					if($wd_grp_num > $stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{words}->{group_num}->{max_count}) {
						$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{words}->{group_num}->{max_count} = $wd_grp_num;
					}
				} ## sentences
			} ## topics

			foreach my $iname (keys %{ $iname_list }) {
#				$all_xero_count_href->{$iname} = $all_xero_count;
#				$sent_ctr_href->{$iname} = $sent_ctr;
#				$sent_words_href->{$iname} = $sent_words;

				if(exists $all_xero_count_href->{$iname}) {
					if(!exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{allcount}->{zero}) {
						$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{allcount}->{zero} = 0;
					}
					$anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{allcount}->{zero} = $all_xero_count_href->{$iname};
				}
				$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{sentences}->{eachs}->{count} = $sent_ctr_href->{$iname};
				$stats_base_disp->{by_iname}->{$iname}->{clustering}->{info}->{words}->{total}->{count} = $sent_words_href->{$iname};
			
			#		my $text_code = $data_coding->{runlinks}->{code_form_mapping}->{$code};

				my $cktr = 0;
				my $zero_density_ctr = 0;
				my $dist_density_sum = 0;
				my $dist_density_ctr = 0;
				my $short_density_sum = 0;
				my $med_density_sum = 0;
				my $large_density_sum = 0;
				my $short_dist_ctr = 0;
				my $med_dist_ctr = 0;
				my $large_dist_ctr = 0;
				if(exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}) {
					foreach my $dist (keys %{ $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances} }) {
						if($dist=~/^zero$/i) {
							$zero_density_ctr = $zero_density_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{zero};
							next;
						}
						$dist_density_sum = $dist_density_sum + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist} * $dist;
						$dist_density_ctr = $dist_density_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist};
						if($dist < ($short_dist_limit + 1)) {
							$short_density_sum = $short_density_sum + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist} * $dist;
							$short_dist_ctr = $short_dist_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist};
						} elsif($dist < ($mid_dist_limit + 1)) {
							$med_density_sum = $med_density_sum + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist} * $dist;
							$med_dist_ctr = $med_dist_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist};
						}
						if($dist > ($mid_dist_limit)) {
							$large_density_sum = $large_density_sum + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist} * $dist;
							$large_dist_ctr = $large_dist_ctr + $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{distances}->{$dist};
						}
						$cktr++;
					}
					my $bases = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{base};
					my $zeros = 0;
					if(exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros}) {
						$zeros = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{hits}->{zeros};
					}
					my $l_bases = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{base};
					my $l_zeros = 0;
					if(exists $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros}) {
						$l_zeros = $anal_coding->{by_iname}->{$iname}->{dispersion}->{base}->{linkage}->{$code}->{struct}->{links}->{zeros};
					}
					if($bases) {
						$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{modus}->{hit_zeros} = ($zeros + $bases) / $bases;
						$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{hits}->{base} = $bases;
						$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{hits}->{zeros} = $zeros;
					}
					if($l_bases) {
						$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{modus}->{link_zeros} = ($l_zeros + $l_bases) / $l_bases;
						$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{links}->{base} = $l_bases;
						$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{mass}->{links}->{zeros} = $l_zeros;
					}
				}
			
#			$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{zeros} = $zero_density_ctr;
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{count} = $dist_density_ctr;
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{sum} = $dist_density_sum;
				if($dist_density_ctr>0) {
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean} = $dist_density_sum / $dist_density_ctr;
				}
				if($dist_density_ctr==0) {
					## no distances available
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{count} = 0;
				}
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean_narrow} = 0;
				$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{sum} = $short_density_sum;

				if($short_dist_ctr) {
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{count} = $short_dist_ctr;
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean_narrow} = $short_density_sum / $short_dist_ctr;
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{narrow}->{mean} = $short_density_sum / $short_dist_ctr;
				} else {
					if($dist_density_ctr) {
						$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean_narrow} = $dist_density_sum / $dist_density_ctr;
					}
				}
				if($med_dist_ctr) {
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{medium}->{count} = $med_dist_ctr;
				}
				if($large_dist_ctr) {
					$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{wide}->{count} = $large_dist_ctr;
				}
			
				$ktr++;
				say "[$me][$iname] Base Disp [$ktr][$cktr] totals(z:ct:sum)[$zero_density_ctr:".$dist_density_ctr.":".$dist_density_sum."]:[$code] mean[".$stats_base_disp->{by_iname}->{$iname}->{dispersion}->{base}->{stats}->{$code}->{total}->{mean}."]" if $trace;
			}
		} ## end of codes loop

		$codes_dirty->{base_dispersion} = 1;
		$codes_dirty->{dispersion} = 1;
					
	}
	return $taskid;

	## declare this variable for the following code...to be removed.
	my $iname = undef;
	
	
	
	my $sentence_href = $data_coding->{$iname}->{re_codes}->{sentences};
#	my $overlap_thres = 1;
#	my $nesting_thres = 7;
#	my $short_dist_limit = 3;
#	my $mid_dist_limit = 27;
	my $ktr = 0;
	my @code_loop = ();
	my $active_sent_codes = {};
	foreach my $code (keys %$code_list) {
		$ktr++;
		push @code_loop,$code;
		my $distance = 0;
		my $first_found = 0;
		my $index = 0;
#		$active_sent_codes->{$code} = [];
#		if(!exists $active_sent_codes->{$code}) {
#			say "!!!! this code [$code] will not hash! Trying quotes";
#			$active_sent_codes->{ qw{$code} } = [];
#			foreach my $cd (keys %$active_sent_codes) {
#				say "\tcode[$cd]";
#			}
#			die;
#		}
		foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
			foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
				my $tskey = $sorter->{$tindex}->{$sindex}->{key};
				my $tskey_re = $sorter->{$tindex}->{$sindex}->{rekey};
				my $fp_key = $file_parse_key;
				my $iname = $data_postparse->{parse_multi_struct}->{multi_txt}->{$fp_key}->{sentence_struct}->{$tskey}->{iname};
				if(!exists $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey_re}) {
					say "[$my_shortform_server_type][$me] iname [$iname] tskey_re[$tskey_re] tskey[$tskey]....codes for sentence list does not exist " if $trace;
					next;
#					die "Not right....line[".__LINE__."]\n";
				}
				my $sentence_codes = $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey_re};
				if(exists $sentence_codes->{ $codes_key } and scalar(keys %{ $sentence_codes->{ $codes_key } })) {
#					my $found = 0;
#					foreach my $cindex (keys %{ $sentence_codes->{ $codes_key } }) {
#						if($sentence_codes->{ $codes_key }->{$cindex}=~/^$code$/i) {
#							$found = 1;
#							last;
#						}
#					}
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_codes,$code,$trace_detail);
					if($found) {
						if(!exists $active_sent_codes->{$code}) {
							$active_sent_codes->{$code} = [];
						}
						my $arr = $active_sent_codes->{$code};
						push @$arr,$tskey;
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
#							$data_coding->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_location} = $tskey;
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_location} = $tskey;
#							$data_coding->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_count} = $index;
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_count} = $index;
							$index++;
							next;
						}
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance}) {
#							$data_coding->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} = 0;
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} = 0;
						}
#						$data_coding->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} = $data_coding->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} + 1;
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$distance} + 1;
						
						## topic clustering
						if(!exists $statcodes->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$tindex}) {
							$statcodes->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$tindex}->{count} = 0;
						}
						$statcodes->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$tindex}->{count} = $statcodes->{$iname}->{re_codes}->{clustering}->{by_topic}->{$code}->{list}->{$tindex}->{count} + 1;
						my $sent_ind = $sentence_ctr{ $tskey };
						if(!exists $statcodes->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sent_ind}) {
							$statcodes->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sent_ind}->{count} = 0;
						}
						$statcodes->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sent_ind}->{count} = $statcodes->{$iname}->{re_codes}->{clustering}->{by_sentence_index}->{$code}->{list}->{$sent_ind}->{count} + 1;
						$distance = 0;
					}
				}
				if($first_found) {
					$distance++;
				}
				$index++;
			}
		}

		foreach my $iname (keys %{ $iname_list }) {
			my $stop_pt = 10;
			my $sum = 0; ## first found does not create a initial distance count...start at 1 for actual count
			my $ktr2 = 0;
			my $short_sum = 0;
			my $med_sum = 0;
			my $large_sum = 0;
			my $t_sum = 0;
			my $short_ct = 0;
			my $med_ct = 0;
			my $large_ct = 0;
			if(exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}) {
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances} }) {
					if(!$sum) { $sum = 1; } ## reset count to one
					$sum = $sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
					$t_sum = $t_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						print "[$me] dispersion [$iname][$code] dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist}."] sum[$sum]" if $trace;
					}
					if($dist < ($short_dist_limit + 1)) {
						$short_ct = $short_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
						$short_sum = $short_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct] short sum[$short_sum]" if $trace;
						}
					} elsif($dist < ($mid_dist_limit + 1)) {
						$med_ct = $med_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
						$med_sum = $med_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct] med sum[$med_sum]" if $trace;
						}
					}
					if($dist > ($mid_dist_limit)) {
						$large_ct = $large_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
						$large_sum = $large_sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct] large sum[$large_sum]" if $trace;
						}
					}
					$ktr2++;
				}
			}

			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{count} = $sum;
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{sum} = $t_sum;
			if(($sum - 1)>0) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean} = $t_sum / ($sum - 1); ## sum is actually *count*
			}
			if($sum==0) {
				## no distances available
				$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{count} = 0;
				$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{count} = 1;
	#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{sum} = 0;
	#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{mean} = 0;
			}
			$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow} = 0;
			
			if($short_ct) {
				$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{count} = $short_ct;
	#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{sum} = $short_sum;
				$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow} = $short_sum / $short_ct;
			} else {
				if($sum) {
					$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total}->{mean_narrow} = $t_sum / $sum;
				}
			}
			if($med_ct) {
				$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{count} = $med_ct;
	#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{sum} = $med_sum;
	#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{mean} = $med_sum / $med_ct;
			}
			if($large_ct) {
				$statlinks->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{count} = $large_ct;
	#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{sum} = $large_sum;
	#			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{mean} = $large_sum / $large_ct;
			}
			$codes_dirty->{dispersion} = 1;
		}
	}

	$ktr = 0;

	return $taskid;
	## skip the other dispersions....too hard, too little value...
	
	## Up-Down dispersion calc
	##
	foreach my $code (keys %$code_list) {
		$ktr++;
		my $c_arr = $active_sent_codes->{$code};
		if(!scalar(@$c_arr)) {
			say "[$me] iname[$iname} GO UP - this base code[$code][$ktr] has no markup; **special chars may not find match**, code arr ct[".scalar(@$c_arr)."]";
			say "\tfix";
#			die "\tstop check...\n";
			next;
		}
		my $code_start_tskey = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_location};
		my $code_start_index = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{first_count};
		my $distance = 0;
		if($ktr > 1000) {
			last;
		}
		my $src_code_ct = 0;
		my $target_code_ct = 0;
		say "[$me] iname[$iname} GO UP for base code[$ktr][$code] start ptr[$code_start_index] start key[$code_start_tskey] s[0] code arr ct[".scalar(@$c_arr)."] sentctr[".scalar(keys %sentence_ctr)."] codeptr[".$sentence_ctr{ $c_arr->[0] }."]" if $trace_updown;
		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
			my $test_code = $code_loop[$cc];
#			if($test_code eq $code) {
#				## same code...skip
#				next;
#			}
			if($code_list->{$code}) {
				## this code has a base code!
				if($code_list->{$test_code}) {
					## the test code also has a base code!
					if($code_list->{$test_code} eq $code_list->{$code}) {
						## same code tree...skip
						next;
					}
				} else {
					if($test_code eq $code_list->{$code}) {
						## base code tree matches open code...skip
						next;
					}
				}
			} else {
				if($code_list->{$test_code}) {
					## the test code has a base code!
					if($code eq $code_list->{$test_code}) {
						## open code matches base of code tree...skip
						next;
					}
				} else {
					if($test_code eq $code) {
						## same code...skip
						next;
					}
				}
			}
			my $s = 0;
			my $temp_tskey = $c_arr->[$s];
			my $code_ptr = $sentence_ctr{ $temp_tskey };
			$s++;
			my $src_ctr = 0;
			my $target_ctr = 0;
			for (my $ss=0; $ss<scalar(@sentences_arr); $ss++) {
				my $tskey = $sentences_arr[$ss];
				if($ss < $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						$distance = $code_ptr - $ss;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$distance} + 1;
						$distance = 0;
						$target_ctr++;
					}
				} elsif($ss == $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero_2x}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero_2x} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero_2x} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero_2x} + 1;
					} else {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{zero} + 1;
					}
					$distance = 0;
					$src_ctr++;
					if($s == scalar(@$c_arr)) {
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF src tskeys, same code ptr[$code_ptr] src code ct[$s]" if $trace;
						$s++;
					} else {
						my $temp_tskey = $c_arr->[$s];
						if(!$temp_tskey) {
							die "\t dying to fix bad temp tskey\n";
						}
						$code_ptr = $sentence_ctr{ $temp_tskey };
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] temp tskey[$temp_tskey] code ptr[$code_ptr] src code ct[$s] size[".scalar(@$c_arr)."] [".$sentence_ctr{ $c_arr->[$s] }."]" if $trace;
						$s++;
					}
				} else {
					if($s > scalar(@$c_arr)) {
						## no more code value in stack
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF test of [$test_code] code ptr[$code_ptr] src code ct[$s]" if $trace;
						last;
					}
					say "[$me] iname[$iname] code[$code] code out of sequence [$ss] ptr[$code_ptr] at [$tskey]";
					die "\tdie to fix\n";
				}
			}
			if($target_ctr) {
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{counts}->{first} = $src_ctr;
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{counts}->{second_up} = $target_ctr;
			}
			$src_code_ct = $src_ctr;
		}
		$distance = 0;
		my $top_index = scalar(@$c_arr) - 1;
		say "[$me] iname[$iname} GO DOWN for base code[$ktr][$code] start key[".$c_arr->[$top_index]."] top s[$top_index] code arr ct[".scalar(@$c_arr)."] codeptr[".$sentence_ctr{ $c_arr->[$top_index] }."]" if $trace_updown;
		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
			my $test_code = $code_loop[$cc];
			if($test_code eq $code) {
				## same code...skip
				next;
			}
			my $s = scalar(@$c_arr) - 1;
			my $temp_tskey = $c_arr->[$s];
			my $code_ptr = $sentence_ctr{ $temp_tskey };
			$s--;
			my $target_ctr = 0;
			my $top_sent = scalar(@sentences_arr) - 1;
			for (my $ss=$top_sent; $ss>=0; $ss--) {
				my $tskey = $sentences_arr[$ss];
				if($ss > $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						$distance = $ss - $code_ptr;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} + 1;
						$distance = 0;
						$target_ctr++;
					}
				} elsif($ss == $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero_2x}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero_2x} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero_2x} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero_2x} + 1;
					} else {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{zero} + 1;
					}
					$distance = 0;
					if($s < 0) {
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF src tskeys, same code ptr[$code_ptr] src code ct[$s]" if $trace;
					} else {
						my $temp_tskey = $c_arr->[$s];
						if(!$temp_tskey) {
							die "\t dying to fix bad temp tskey\n";
						}
						$code_ptr = $sentence_ctr{ $temp_tskey };
						$s--;
					}
				} else {
					if($s < 0) {
						## no more code value in stack
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF test of [$test_code] code ptr[$code_ptr] src code ct[$s]" if $trace;
						last;
					}
					say "[$me] iname[$iname] code[$code] code out of sequence [$ss] ptr[$code_ptr] at [$tskey]";
					die "\tdie to fix\n";
				}
			}
			if($target_ctr) {
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{counts}->{first} = $src_code_ct;
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{counts}->{second_dn} = $target_ctr;
				$target_code_ct = $target_ctr;
			}
		}
		say "[$me] iname[$iname} MAKE STATS for base code[$ktr][$code] src_code arr ct[".scalar(@$c_arr)."] target/2nd code ct[$target_code_ct]" if $trace_stats;
		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
			my $test_code = $code_loop[$cc];
			if($test_code eq $code) {
				## same code...skip
				next;
			}
			my $short_dist_limit2 = 27;
			my $mid_dist_limit2 = 81;
			my $stop_pt = 0;
			my $ktr2 = 0;
			my $match_ct = 0;
			my $no_match_ct = 0;
			my $count2 = 0; ## found creates an initial distance count
			my $sum2 = 0; ## found creates an initial distance count
			my $short_sum2 = 0;
			my $med_sum2 = 0;
			my $large_sum2 = 0;
			my $short_ct2 = 0;
			my $med_ct2 = 0;
			my $large_ct2 = 0;
			if(exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}) {
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up} }) {
					if($dist eq 'zero_2x') {
						$match_ct = $match_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						next;
					}
					if($dist eq 'zero') {
						$no_match_ct = $match_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						next;
					}
					$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
					$sum2 = $sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						print "[$me] dispersion [$iname][$code] dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist}."] sum[$count2]" if $trace;
					}
					if($dist < ($short_dist_limit2 + 1)) {
						$short_ct2 = $short_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						$short_sum2 = $short_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct2] short sum[$short_sum2]" if $trace;
						}
					} elsif($dist < ($mid_dist_limit2 + 1)) {
						$med_ct2 = $med_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						$med_sum2 = $med_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct2] med sum[$med_sum2]" if $trace;
						}
					}
					if($dist > ($mid_dist_limit2)) {
						$large_ct2 = $large_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist};
						$large_sum2 = $large_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct2] large sum[$large_sum2]" if $trace;
						}
					}
				}
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down} }) {
					if($dist eq 'zero_2x') {
						$match_ct = $match_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						next;
					}
					if($dist eq 'zero') {
						$no_match_ct = $match_ct + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						next;
					}
					$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
					$sum2 = $sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						print "[$me] dispersion-dn [$iname][$code] dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist}."] sum[$count2]" if $trace_stats;
					}
					if($dist < ($short_dist_limit2 + 1)) {
						$short_ct2 = $short_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						$short_sum2 = $short_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct2] short sum[$short_sum2]" if $trace_stats;
						}
					} elsif($dist < ($mid_dist_limit2 + 1)) {
						$med_ct2 = $med_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						$med_sum2 = $med_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct2] med sum[$med_sum2]" if $trace_stats;
						}
					}
					if($dist > ($mid_dist_limit2)) {
						$large_ct2 = $large_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist};
						$large_sum2 = $large_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct2] large sum[$large_sum2]" if $trace_stats;
						}
					}
				}
				$ktr2++;
			}
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{count} = 0;
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{sum} = $sum2;
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{mean} = 0;
			if($count2) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{count} = $count2;
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total}->{mean} = $sum2 / $count2;
			}
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{match_count} = $match_ct;
			$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{no_match_count} = $no_match_ct;
			if($match_ct) {
				my $per = 10 * ($match_ct / ($match_ct + $no_match_ct));
				my $per2 = 10 * ($match_ct / $count2);
				if($per2=~/(\d+)\.*([\d]*)/) {
					 if($1 > $overlap_thres) {
						$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_overlap} = $1;
					 }
				}
				if($per=~/(\d+)\.*([\d]*)/) {
					 if($1 >= $nesting_thres and $1 < 10) {
						$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_partial_nesting_first_in_second} = $1;
					 }
					 if($1 == 10) {
						$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_complete_nesting_first_in_second} = $1;
						my $size = 1;
						if(exists $statcodes->{$iname}->{re_codes}->{nesting}->{complete}->{$code}) {
							$size = scalar(keys %{ $statcodes->{$iname}->{re_codes}->{nesting}->{complete}->{$code} });
						}
						$statcodes->{$iname}->{re_codes}->{nesting}->{complete}->{$code}->{$size}->{within} = $test_code;
						$statcodes->{$iname}->{re_codes}->{nesting}->{complete}->{$code}->{$size}->{count} = $match_ct;
					 }				 
				}
				if($match_ct == $count2) {
					$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_complete_nesting_second_in_first} = 10;
					my $size = 1;
					if(exists $statcodes->{$iname}->{re_codes}->{nesting}->{complete}->{$test_code}) {
						$size = scalar(keys %{ $statcodes->{$iname}->{re_codes}->{nesting}->{complete}->{$test_code} });
					}
					$statcodes->{$iname}->{re_codes}->{nesting}->{complete}->{$test_code}->{$size}->{within} = $code;
					$statcodes->{$iname}->{re_codes}->{nesting}->{complete}->{$test_code}->{$size}->{count} = $match_ct;
				}
			}
			if($short_ct2) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{narrow}->{count} = $short_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{narrow}->{sum} = $short_sum2;
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{narrow}->{mean} = $short_sum2 / $short_ct2;
			}
			if($med_ct2) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{medium}->{count} = $med_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{medium}->{sum} = $med_sum2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{medium}->{mean} = $med_sum2 / $med_ct2;
			}
			if($large_ct2) {
				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{wide}->{count} = $large_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{wide}->{sum} = $large_sum2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{wide}->{mean} = $large_sum2 / $large_ct2;
			}
		}
	}

	## 2x dispersion
	$ktr = 0;
	foreach my $code (keys %$code_list) {
		$ktr++;
		my $c_arr = $active_sent_codes->{$code};
		if(!scalar(@$c_arr)) {
			say "[$me] iname[$iname} GO UP - this base code[$code][$ktr] has no markup; **special chars may not find match**, code arr ct[".scalar(@$c_arr)."]";
			say "\tfix";
#			die "\tstop check...\n";
			next;
		}
		my $distance = 0;
		my $distance_src = 0;
		my $double_hit = 2;
		my $index = 0;
		if($ktr > 1000) {
			last;
		}
		my $src_code_ct = 0;
		my $ktr2 = 0;
		say "[$me] iname[$iname} 2X Disp for base code[$ktr][$code] s[0] code arr ct[".scalar(@$c_arr)."] codeptr[".$sentence_ctr{ $c_arr->[0] }."]" if $trace_2x;
		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
			my $test_code = $code_loop[$cc];
			
			## check for whether codes match singular codes or code trees
			if($code_list->{$code}) {
				## this code has a base code!
				if($code_list->{$test_code}) {
					## the test code also has a base code!
					if($code_list->{$test_code} eq $code_list->{$code}) {
						## same code tree...skip
						next;
					}
				} else {
					if($test_code eq $code_list->{$code}) {
						## base code tree matches open code...skip
						next;
					}
				}
			} else {
				if($code_list->{$test_code}) {
					## the test code has a base code!
					if($code eq $code_list->{$test_code}) {
						## open code matches base of code tree...skip
						next;
					}
				} else {
					if($test_code eq $code) {
						## same code...skip
						next;
					}
				}
			}
#			if($test_code eq $code) {
#				## same code...skip
#				next;
#			}

			my $s = 0;
			my $first_found = 0;
			my $temp_tskey = $c_arr->[$s];
			my $code_ptr = $sentence_ctr{ $temp_tskey };
			$s++;
			my $src_ctr = 0;
			my $target_ctr = 0;
			for (my $ss=0; $ss<scalar(@sentences_arr); $ss++) {
				my $tskey = $sentences_arr[$ss];
				if($ss < $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found and $s == 1) {
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
							$index++;
							say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance] ss<ptr (1-1), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
							next;
						}
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						say "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss < ptr (1-2), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} elsif($found) {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						say "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] ss < ptr (2), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} elsif($s > 1) {
						$distance++;
						$distance_src++;
					} else {
						if($first_found) {
							$distance++;
						}
					}
#					say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] ss < ptr seq, ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
				} elsif($ss == $code_ptr) {
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found and $s == 1) {
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
							$distance_src = 1;
							if($s == scalar(@$c_arr)) {
								$distance_src = 0;
#							$s++;
							} else {
								my $temp_tskey = $c_arr->[$s];
								if(!$temp_tskey) {
									die "\t dying to fix bad temp tskey\n";
								}
								$code_ptr = $sentence_ctr{ $temp_tskey };
#								say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] temp tskey[$temp_tskey] code ptr[$code_ptr] src code ct[$s] size[".scalar(@$c_arr)."] [".$sentence_ctr{ $c_arr->[$s] }."]" if $trace;
							}
							$s++;
							next;
						}
#						my $double_hit = 2;
						if($s == scalar(@$c_arr)) {
							$distance_src = 0;
						} else {
							my $temp_tskey = $c_arr->[$s];
							if(!$temp_tskey) {
								die "\t dying to fix bad temp tskey\n";
							}
							$code_ptr = $sentence_ctr{ $temp_tskey };
						}
						$s++;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + $double_hit;
						## (1)
						say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss==ptr (1), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} elsif($found) {
						if($s == scalar(@$c_arr)) {
							$distance_src = 0;
						} else {
							my $temp_tskey = $c_arr->[$s];
							if(!$temp_tskey) {
								die "\t dying to fix bad temp tskey\n";
							}
							$code_ptr = $sentence_ctr{ $temp_tskey };
						}
						$s++;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + $double_hit;
						## (2)
						say "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss==ptr (2), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} elsif($s > 1) {
						## been to first ptr
						$distance_src = 1;
						if($s == scalar(@$c_arr)) {
							$distance_src = 0;
						} else {
							my $temp_tskey = $c_arr->[$s];
							if(!$temp_tskey) {
								die "\t dying to fix bad temp tskey\n";
							}
							$code_ptr = $sentence_ctr{ $temp_tskey };
						}
						$s++;
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						## (3)
						print "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss==ptr (3), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						if($distance_src) {
							say "" if $trace_2x;
						} else {
							say "-end" if $trace_2x;
						}
						$distance = 1;
					} else { ## case is s==1, no found
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
							$distance_src = 1;
							if($s == scalar(@$c_arr)) {
								$distance_src = 0;
							} else {
								my $temp_tskey = $c_arr->[$s];
								if(!$temp_tskey) {
									die "\t dying to fix bad temp tskey\n";
								}
								$code_ptr = $sentence_ctr{ $temp_tskey };
							}
							$s++;
							## (4-1)
							say "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance] ss==ptr (4-1), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
							next;
						}
						$distance_src++;
						if($s == scalar(@$c_arr)) {
							$distance_src = 0;
						} else {
							my $temp_tskey = $c_arr->[$s];
							if(!$temp_tskey) {
								die "\t dying to fix bad temp tskey\n";
							}
							$code_ptr = $sentence_ctr{ $temp_tskey };
						}
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						$s++;
						$distance++;
						say "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss==ptr (4), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
					}
#					say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] ss == ptr seq, ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]";

				} else {
					## no more src codes in sentences field
					my $found = &check_for_code_match($taskid,$codes_key,$sentence_href->{$tskey},$test_code,$trace_detail);
					if($found) {
						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}) {
							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance} + 1;
						## found (fd)
						say "[$me] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$distance}."] ss > ptr (fd), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
						$distance = 1;
					} else {
						$distance++;
						## (+)
#						say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code][$test_code] f[$found] f1[$first_found] dist[$distance][+] ss > ptr (+), ss[$ss] ptr[$code_ptr] at [$tskey] s[$s]" if $trace_2x;
					}
				}
			}
			my $short_dist_limit2 = 3;
			my $mid_dist_limit2 = 27;
			my $stop_pt = 1;
			my $match_ct = 0;
			my $count2 = 1;
			my $sum2 = 1;
			my $short_sum2 = 0;
			my $med_sum2 = 0;
			my $large_sum2 = 0;
			my $short_ct2 = 0;
			my $med_ct2 = 0;
			my $large_ct2 = 0;
			if(exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}) {
				say "[$me] iname[$iname] code[$code][$test_code] loop *two* values" if $trace_2x;
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two} }) {
					$count2 = $count2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist};
					$sum2 = $sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						print "[$me] [$iname][$ktr][$code][$test_code] 2x stats, dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist}."] ct[$count2]" if $trace_stats;
					}
					if($dist < ($short_dist_limit2 + 1)) {
						$short_ct2 = $short_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist};
						$short_sum2 = $short_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct2] short sum[$short_sum2]" if $trace_stats;
						}
					} elsif($dist < ($mid_dist_limit2 + 1)) {
						$med_ct2 = $med_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist};
						$med_sum2 = $med_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct2] med sum[$med_sum2]" if $trace_stats;
						}
					}
					if($dist > ($mid_dist_limit2)) {
						$large_ct2 = $large_ct2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist};
						$large_sum2 = $large_sum2 + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{distances}->{two}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct2] large sum[$large_sum2]" if $trace_stats;
						}
					}
					$ktr2++;
				}
			}
			if($count2 > ($short_ct2 + $med_ct2 + $large_ct2 + 1)) {
				say "\t\t2x Counts BROKE! total[$count2] != short[$short_ct2] + med[$med_ct2] + large[$large_ct2] + 1";
			}
			$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{total}->{count} = $count2;
			$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{total}->{sum} = $sum2;
			if($count2) {
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{total}->{mean} = $sum2 / $count2;
			}
			if($short_ct2) {
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{narrow}->{count} = $short_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{narrow}->{sum} = $short_sum2;
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{narrow}->{mean} = $short_sum2 / $short_ct2;
			}
			if($med_ct2) {
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{medium}->{count} = $med_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{medium}->{sum} = $med_sum2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{medium}->{mean} = $med_sum2 / $med_ct2;
			}
			if($large_ct2) {
				$statcodes2x->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{wide}->{count} = $large_ct2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{wide}->{sum} = $large_sum2;
#				$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_2x}->{$code}->{$test_code}->{stats}->{wide}->{mean} = $large_sum2 / $large_ct2;
			}
		}
	}

	return $taskid;
}
sub make_summary_dispersion_stats {
	my ($cat,$taskid,$trace) = @_;
	my $me = "SUMM-CODE-DISP";
	$me = $me . "][taskid:$taskid][cat:$cat";

	my $trace_detail = 0;
	my $trace_sum = 0;

	my %place_ctr = ();
	my $ct = 1;
	foreach my $iname (keys %{ $run_status->{active_xls_iname_percodestats} }) {
		$place_ctr{$iname} = $ct;
		$ct++;
	}
	say "[$me] active iname ct[".scalar(keys %place_ctr)."]" if $trace;

	$stats_base_disp->{all_inames}->{clustering} = {};

	if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} and !scalar(keys %{ $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes} })) {
		say "[$me] prime codehref error...prime code list is not valid!";
		die "\tdying to fix at[".__LINE__."]\n";
	}
	my $prime_codehref = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes};
	say "[$me] prime codes loaded...size[".scalar(keys %$prime_codehref)."]" if $trace;
		
	if(scalar(keys %$prime_codehref)) {
		my $ktr = 0;
		my $low_limit = 1;
		if(exists $post_text_config->{prime_code_count_low_limit} and $post_text_config->{prime_code_count_low_limit}) {
			$low_limit = $post_text_config->{prime_code_count_low_limit};
		}
		my $_sorter = {};
		foreach my $code (keys %$prime_codehref) {
			my $total = 0;
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count}) {
				$total = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count};
			}
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree} and $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count}) {
				$total = $total + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count};
			}
			$_sorter->{$code} = $total;
		}
		say "[$me] prime sorter hash...size[".scalar(keys %$_sorter)."]" if $trace;
		foreach my $code (sort { $_sorter->{$b} <=> $_sorter->{$a} } keys %$_sorter) {
			my $allcount = $_sorter->{$code};
			if($low_limit > $allcount) {
				say " [$me] prime code limiter, PER_code_stats, code[$code] code size too small[".$allcount."]" if $trace_detail;
				next;
			}
			my $all_count = {};
			my $iname_ctr = 0;
#			$stats_base_disp->{all_inames}->{clustering}->{by_code}->{$code}->{by_word_grp} = {};
			foreach my $iname (keys %place_ctr) {
				if(exists $stats_base_disp->{by_iname}->{$iname}) {
					my $counts = 0;
					if(exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}) {
						if(exists $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}) {
							foreach my $index (sort{ $a <=> $b } keys %{ $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp} }) {
								my $pts = $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$index}->{count};
								if(!exists $all_count->{$code}->{$index}) {
									$all_count->{$code}->{$index} = 0;
								}
								$counts++;
								$all_count->{$code}->{$index} = $all_count->{$code}->{$index} + $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$index}->{count};
								say "[$me][$iname] loop sum [$index] value[".$pts."] code[$code] " if $trace_sum;
							}
#							say "[$me][$iname] prime code summary, word grps[".scalar(keys %$all_count)."] from grps[".scalar(keys %{ $stats_base_disp->{by_iname}->{$iname}->{clustering}->{by_code}->{$code}->{by_word_grp} })."] code[$code] ";
						}
					}
					say "[$me][$iname] prime code summary, word grps[".scalar(keys %$all_count)."] cts[$counts] code[$code] " if $trace_detail;
					$iname_ctr++;
				}
			}
			say "[$me] inamectr[$iname_ctr] prime code summary, word grps[".scalar(keys %$all_count)."] code[$code] " if $trace;
			foreach my $index (keys %{ $all_count->{$code} }) {
				$stats_base_disp->{all_inames}->{clustering}->{by_code}->{$code}->{by_word_grp}->{$index}->{count} = $all_count->{$code}->{$index};
			}
			
#  clustering:
 #   by_code:
  #    AE designer interest:
   #     by_word_grp:
    #      '39': 182464368
    #      '40': 186015968
    #  EE:
    #    by_word_grp:
    #      '1': 1229182296
    #      '10': 564189896
    #      '100': 357282800
			
		}
		$codes_dirty->{base_dispersion} = 1;
		$codes_dirty->{dispersion} = 1;
	}
	return $taskid;
}
sub check_for_code_match {
	####
	my ($taskid,$codes_key,$href,$codetest,$trace) = @_;
	my $found = 0;
	my $blank_arg = undef;
	if(exists $href->{ $codes_key } and scalar(keys %{ $href->{ $codes_key } })) {
		foreach my $cindex (keys %{ $href->{ $codes_key } }) {
			if($cindex > 100) {
				## not a real code...skip
				next;
			}

			## get codes from possible embedded code tree
			my $codetree = $href->{ $codes_key }->{$cindex};
			my $clayers = &make_code_layers($codetree,$blank_arg,$taskid,$trace);
			foreach my $lindex (keys %$clayers) {
				my $code = $clayers->{$lindex};
				if($code=~/^$codetest$/i) {
					$found = 1;
					say "\t[taskid:$taskid][$codes_key] code MATCH [$codetest] fount" if $trace; 
					last;
				}
			}
		}
	}
	return $found;
}
sub set_aspect_dispersion {
	my ($cat,$taskid,$sentence_href,$aspect_list,$code_list,,$iname,$trace) = @_;
	my $me = "SET-ASPECT-DISP";
	$me = $me . "][taskid:$taskid][cat:$cat";

	my $trace_detail = 0;
	my $trace_updown = 0;
	my $trace_stats = 1;

	if(!exists $data_analysis->{by_iname}) {
		$data_analysis->{by_iname} = {};
	}
	my $analcodes = $data_analysis->{by_iname};

#	if(!exists $data_stats->{by_iname}) {
#		$data_stats->{by_iname} = {};
#	}
	if(!exists $data_stats_aspects->{by_iname}) {
		$data_stats_aspects->{by_iname} = {};
	}
	my $statcodes = $data_stats_aspects->{by_iname};

	my $sorter = {};
	my $cctr = 0;
	foreach my $tskey (keys %$sentence_href) {
		if($tskey=~/^t(\d+)s(\d+)/i) {
			my $t = $1;
			my $s = $2;
			$sorter->{$t}->{$s} = $tskey;
			$cctr++;
		}
	}
	say "[$me] iname[$iname] post sentence sorter, [$cctr] sentences";

	my @sentences_arr = ();
	my %sentence_ctr = ();
	$cctr = 0;
	foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
		foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
			push @sentences_arr,$sorter->{$tindex}->{$sindex};
			$sentence_ctr{ $sorter->{$tindex}->{$sindex} } = $cctr;
			$cctr++;
		}
	}

	my $sent_ct_size = 55;
	my $overlap_thres = 1;
	my $nesting_thres = 7;
	my $short_dist_limit = 3;
	my $mid_dist_limit = 27;

	my $ktr = 0;
	my @aspect_loop = ();
	my $active_sent_aspects = {};
	foreach my $aspect (keys %$aspect_list) {
		$ktr++;
		push @aspect_loop,$aspect;
		my $distance = 0;
		my $first_found = 0;
		$active_sent_aspects->{$aspect} = [];
		my $sent_ctr = 0;
		foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
			foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
				my $tskey = $sorter->{$tindex}->{$sindex};
				$sent_ctr++;

				my $grp_num = $sent_ctr / $sent_ct_size;
				## give NO digits to the right
				if($grp_num=~/([\d]+)(\.[\d]+)/) {
					$grp_num = $1;
				}
				$grp_num++;
				if(exists $sentence_href->{$tskey}->{aspects} and scalar(keys %{ $sentence_href->{$tskey}->{aspects} })) {
					my $found = 0;
					my $rating = 0;
					foreach my $aspect2 (keys %{ $sentence_href->{$tskey}->{aspects} }) {
						if($aspect2=~/^$aspect$/i) {
							$found = 1;
							$rating = $sentence_href->{$tskey}->{aspects}->{$aspect};
							last;
						}
					}

					## sent group clustering
					if(!exists $stats_base_disp->{by_iname}->{$iname}->{aspect_clustering}->{by_aspect}->{$aspect}) {
						$stats_base_disp->{by_iname}->{$iname}->{aspect_clustering}->{by_aspect}->{$aspect}->{by_sentence_grp}->{$grp_num}->{count} = 0;
					}
					if(!exists $stats_base_disp->{by_iname}->{$iname}->{aspect_clustering}->{by_sentence_grp}->{$grp_num}) {
						$stats_base_disp->{by_iname}->{$iname}->{aspect_clustering}->{by_sentence_grp}->{$grp_num}->{by_aspect}->{$aspect}->{count} = 0;
					}
					if($found) {
						my $arr = $active_sent_aspects->{$aspect};
						push @$arr,$tskey;
						if(!exists $analcodes->{$iname}->{re_aspects}->{ratings}->{by_value}->{$aspect}->{ratings}->{$rating}) {
							$analcodes->{$iname}->{re_aspects}->{ratings}->{by_value}->{$aspect}->{ratings}->{$rating} = 0;
						}
						$analcodes->{$iname}->{re_aspects}->{ratings}->{by_value}->{$aspect}->{ratings}->{$rating} = $analcodes->{$iname}->{re_aspects}->{ratings}->{by_value}->{$aspect}->{ratings}->{$rating} + 1;
						
						## topic clustering
						if(!exists $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_topic}->{$aspect}->{list}->{$tindex}->{count}) {
							$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_topic}->{$aspect}->{list}->{$tindex}->{count} = 0;
						}
						$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_topic}->{$aspect}->{list}->{$tindex}->{count} = $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_topic}->{$aspect}->{list}->{$tindex}->{count} + 1;
						my $sent_ind = $sentence_ctr{ $sorter->{$tindex}->{$sindex} };
						if(!exists $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_sentence_key}->{$aspect}->{list}->{$tskey}) {
							$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_sentence_key}->{$aspect}->{list}->{$tskey}->{rating} = 0;
							$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_sentence_key}->{$aspect}->{list}->{$tskey}->{chars} = 0;
						}
						$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_sentence_key}->{$aspect}->{list}->{$tskey}->{rating} = $rating;
						if(!exists $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{chars}->{count}) {
							$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{chars}->{count} = 0;
						}
						if(!exists $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{count}) {
							$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{count} = 0;
							$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{sum} = 0;
						}
						my $chars_ct = 0;
						
						my $fkey = $data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_parse_key};
						if(!$fkey) {
							say "[$my_shortform_server_type][$me] iname[$iname] data structure failure...no fkey to find remap tskeys at tskey[$tskey]";
							die "\tdying to fix\n";
						}

						## sent group clustering
						$stats_base_disp->{by_iname}->{$iname}->{aspect_clustering}->{by_aspect}->{$aspect}->{by_sentence_grp}->{$grp_num}->{count} = $stats_base_disp->{by_iname}->{$iname}->{aspect_clustering}->{by_aspect}->{$aspect}->{by_sentence_grp}->{$grp_num}->{count} + 1;
						$stats_base_disp->{by_iname}->{$iname}->{aspect_clustering}->{by_sentence_grp}->{$grp_num}->{by_aspect}->{$aspect}->{count} = $stats_base_disp->{by_iname}->{$iname}->{aspect_clustering}->{by_sentence_grp}->{$grp_num}->{by_aspect}->{$aspect}->{count} + 1;
							
						
						if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}) {
							## check for tskey existence, if not die to fix
							if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$tskey} or !$data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$tskey}) {
								say "[$my_shortform_server_type][$me] iname[$iname] fkey[$fkey] post_coding, NOT able to remap tskey[$tskey] ... no value!";
								die "\tdying to fix\n";
							}
							my $_tskey = $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$tskey}->{tskey_map};
							if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}->{$_tskey}->{counts}->{chars}) {
								$chars_ct = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}->{$_tskey}->{counts}->{chars};
							}
						} else {
							if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{chars}) {
								$chars_ct = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{counts}->{chars};
							}
						}
						$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_sentence_key}->{$aspect}->{list}->{$tskey}->{chars} = $chars_ct; ##$data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{chars}->{count};
						$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{chars}->{count} = $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{chars}->{count} + $chars_ct; ##$data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{chars}->{count};

						$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{count} = $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{count} + 1;
						$data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{sum} = $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{sum} + $rating;

						if($rating > 1) {
							my $sentence = '';
							if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}) {
								## check for tskey existence, if not die to fix
								if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$tskey} or !$data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$tskey}) {
									say "[$my_shortform_server_type][$me] iname[$iname] fkey[$fkey] post_coding, NOT able to remap tskey[$tskey] ... no value!";
									die "\tdying to fix\n";
								}
								my $_tskey = $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$tskey}->{tskey_map};

#							my $_tskey = $data_postparse->{parse_multi_struct}->{multi_txt}->{sentence_struct}->{$tskey}->{tskey_map};
								if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}->{$_tskey}->{sentence}) {
									$sentence = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}->{$_tskey}->{sentence};
								}
							} else {
								if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{sentence}) {
									$sentence = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{sentence};
								}
							}
							$statcodes->{$iname}->{re_aspects}->{ratings}->{critical}->{by_aspect}->{$aspect}->{by_rating}->{$rating}->{$tskey}->{text} = $sentence;
#							$statcodes->{$iname}->{re_aspects}->{ratings}->{critical}->{by_tskey}->{$tskey}->{by_rating}->{$rating}->{$aspect}->{text} = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{sentence};
							$statcodes->{$iname}->{re_aspects}->{ratings}->{critical}->{by_tskey}->{$tskey}->{by_aspect}->{$aspect}->{rating} = $rating;
#							$statcodes->{$iname}->{re_aspects}->{ratings}->{critical}->{by_tskey}->{$tskey}->{by_aspect}->{$aspect}->{text} = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}->{$tskey}->{sentence};
							if(!exists $data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_rank}) {
								$data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_rank} = $rating;
								$data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_iname} = $iname;
								$data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{sentence_text} = $sentence;
							}
							$data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_rank} = $data_stats_aspects->{tskey_ranking}->{re_aspects}->{critical_text}->{$tskey}->{by_rank} + $rating;
						}
						if(!$first_found) {
							$first_found = 1;
							$distance = 1;
#							$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{first_location} = $tskey;
							next;
						}
						if(!exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$distance}) {
							$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$distance} = $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$distance} + 1;
						$distance = 0;
					}
				}
				if($first_found) {
					$distance++;
				}
			}
		}
		my $stop_pt = 2;
		my $sum = 0; ## first found does not create a initial distance count...start at 1 for actual count
		my $ktr2 = 0;
		my $t_sum = 0;
		my $short_sum = 0;
		my $med_sum = 0;
		my $large_sum = 0;
		my $short_ct = 0;
		my $med_ct = 0;
		my $large_ct = 0;
		if(exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}) {
			foreach my $dist (keys %{ $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances} }) {

			#$sum = $sum + $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{distances}->{$dist};
				$t_sum = $t_sum + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist} * $dist;
				$sum = $sum + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist};
				if($ktr2 < $stop_pt) {
					print "[cat:$cat][taskid:$taskid] [$iname] aspect[$ktr][$aspect] inner dispersion, dist[$dist] ct[".$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist}."] sum[$sum]" if $trace;
				}
				if($dist < ($short_dist_limit + 1)) {
					$short_ct = $short_ct + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist};
					$short_sum = $short_sum + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						say "  short ct[$short_ct] short sum[$short_sum]" if $trace;
					}
				} elsif($dist < ($mid_dist_limit + 1)) {
					$med_ct = $med_ct + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist};
					$med_sum = $med_sum + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						say "  med ct[$med_ct] med sum[$med_sum]" if $trace;
					}
				}
				if($dist > ($mid_dist_limit)) {
					$large_ct = $large_ct + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist};
					$large_sum = $large_sum + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion}->{$aspect}->{distances}->{$dist} * $dist;
					if($ktr2 < $stop_pt) {
						say "  large ct[$large_ct] large sum[$large_sum]" if $trace;
					}
				}
				$ktr2++;
			}
		}
		if(exists $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_sentence_key}->{$aspect}->{list}) {
			my $ct_sum = 0;
			foreach my $tskey (keys %{ $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_sentence_key}->{$aspect}->{list} }) {
				$ct_sum = $ct_sum + $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{by_sentence_key}->{$aspect}->{list}->{$tskey}->{chars};
			}
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{chars}->{total}->{count} = $ct_sum;
		}
		$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{total}->{count} = $sum; ## really *count*
		$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{total}->{sum} = $t_sum;
		if($sum==1) {
			## no distances available
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{narrow}->{count} = 0;
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{narrow}->{sum} = 0;
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{narrow}->{mean} = 0;
		}
		$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{total}->{mean_narrow} = 0;
		
		if($short_ct) {
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{narrow}->{count} = $short_ct;
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{narrow}->{sum} = $short_sum;
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{narrow}->{mean} = $short_sum / $short_ct;
		} else {
			if($sum) {
				$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{total}->{mean_narrow} = $t_sum / $sum;
			}
		}
		if($med_ct) {
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{medium}->{count} = $med_ct;
#			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{$aspect}->{stats}->{medium}->{sum} = $med_sum;
#			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{$aspect}->{stats}->{medium}->{mean} = $med_sum / $med_ct;
		}
		if($large_ct) {
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{dispersion}->{$aspect}->{stats}->{wide}->{count} = $large_ct;
#			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{$aspect}->{stats}->{wide}->{sum} = $large_sum;
#			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{$aspect}->{stats}->{wide}->{mean} = $large_sum / $large_ct;
		}

		$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{ratings}->{$aspect}->{stats}->{total}->{count} = 0;
		$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{ratings}->{$aspect}->{stats}->{total}->{sum} = 0;
		$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{ratings}->{$aspect}->{stats}->{total}->{mean} = 0;
		if(exists $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{count} and $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{count}) {
			my $cc = $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{count};
			my $ss = $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{ratings}->{sum};
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{ratings}->{$aspect}->{stats}->{total}->{count} = $cc;
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{ratings}->{$aspect}->{stats}->{total}->{sum} = $ss;
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{ratings}->{$aspect}->{stats}->{total}->{mean} = $ss / $cc;
		}
		if(exists $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{chars}->{count} and $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{chars}->{count}) {
			$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{chars}->{$aspect}->{stats}->{total}->{count} = $data_clustering->{by_iname}->{$iname}->{re_aspects}->{clustering}->{totals}->{$aspect}->{chars}->{count};
		}

		say "[cat:$cat][taskid:$taskid] iname[$iname} aspect[$ktr][$aspect] MAKE ratings STATS, ratings ct[".$statcodes->{$iname}->{re_aspects}->{aspect_stats}->{ratings}->{$aspect}->{stats}->{total}->{count}."] " if $trace_stats;
		$codes_dirty->{dispersion} = 1;
		$codes_dirty->{base_dispersion} = 1;
		$codes_dirty->{aspect_dispersion} = 1;

	}

	## aspect-to-code dispersion
	$ktr = 0;
	foreach my $aspect (keys %$aspect_list) {
		$ktr++;
		my $c_arr = $active_sent_aspects->{$aspect};
		if(!scalar(@$c_arr)) {
			say "[cat:$cat][taskid:$taskid] iname[$iname} GO UP - this base code[$aspect][$ktr] has no markup; **special chars may not find match**, code arr ct[".scalar(@$c_arr)."]";
			say "\tfix";
#			die "\tstop check...\n";
			next;
		}
		my $distance = 0;
		my $src_code_ct = 0;
		my $target_code_ct = 0;
		foreach my $code (keys %$code_list) {
			my $s = 0;
			my $first_found = 0;
			my $temp_tskey = $c_arr->[$s];
			my $code_ptr = $sentence_ctr{ $temp_tskey };
			$s++;
			my $src_ctr = 0;
			my $target_ctr = 0;
			for (my $ss=0; $ss<scalar(@sentences_arr); $ss++) {
				my $tskey = $sentences_arr[$ss];
				if($ss < $code_ptr) {
					my $found = &check_for_code_match($taskid,$iname,$sentence_href->{$tskey},$code,$trace_detail);
					if($found) {
						$distance = $code_ptr - $ss;
						if(!exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$distance}) {
							$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$distance} = $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$distance} + 1;
						$distance = 0;
						$target_ctr++;
					}
				} elsif($ss == $code_ptr) {
					my $found = &check_for_code_match($taskid,$iname,$sentence_href->{$tskey},$code,$trace_detail);
					if($found) {
						if(!exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{zero_2x}) {
							$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{zero_2x} = 0;
						}
						$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{zero_2x} = $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{zero_2x} + 1;

					} else {
						if(!exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{zero}) {
							$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{zero} = 0;
						}
						$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{zero} = $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{zero} + 1;

					}
					$distance = 0;
					if($s == scalar(@$c_arr)) {
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF src tskeys, same code ptr[$code_ptr] src code ct[$s]" if $trace;
						$s++;
					} else {
						my $temp_tskey = $c_arr->[$s];
						if(!$temp_tskey) {
							die "\t dying to fix bad temp tskey\n";
						}
						$code_ptr = $sentence_ctr{ $temp_tskey };
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] temp tskey[$temp_tskey] code ptr[$code_ptr] src code ct[$s] size[".scalar(@$c_arr)."] [".$sentence_ctr{ $c_arr->[$s] }."]" if $trace;
						$s++;
					}
				} else {
					if($s > scalar(@$c_arr)) {
						## no more code value in stack
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF test of [$test_code] code ptr[$code_ptr] src code ct[$s]" if $trace;
						last;
					}
					say "[cat:$cat][taskid:$taskid] iname[$iname] code[$code] code out of sequence [$ss] ptr[$code_ptr] at [$tskey]";
					die "\tdie to fix\n";
				}
			}
			if($target_ctr) {
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code}->{counts}->{first} = $src_ctr;
				$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code}->{counts}->{second_up} = $target_ctr;
			}
			$src_code_ct = $src_ctr;
		}
		$distance = 0;
		my $top_index = scalar(@$c_arr) - 1;
		say "[cat:$cat][taskid:$taskid] iname[$iname} GO DOWN for aspect[$ktr][$aspect] start key[".$c_arr->[$top_index]."] top s[$top_index] code arr ct[".scalar(@$c_arr)."] codeptr[".$sentence_ctr{ $c_arr->[$top_index] }."]" if $trace_updown;
#		$target_ctr = 0;
		foreach my $code (keys %$code_list) {
#		for (my $cc=0; $cc<scalar(@code_loop); $cc++) {
#			my $code = $code_loop[$cc];

			my $s = scalar(@$c_arr) - 1;
			my $temp_tskey = $c_arr->[$s];
			my $code_ptr = $sentence_ctr{ $temp_tskey };
			$s--;
			my $target_ctr = 0;
			my $top_sent = scalar(@sentences_arr) - 1;
			for (my $ss=$top_sent; $ss>=0; $ss--) {
				my $tskey = $sentences_arr[$ss];
				if($ss > $code_ptr) {
					my $found = &check_for_code_match($taskid,$iname,$sentence_href->{$tskey},$code,$trace_detail);
					if($found) {
						$distance = $ss - $code_ptr;
						if(!exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$distance}) {
							$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$distance} = 0;
						}
						$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$distance} = $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$distance} + 1;

#						if(!exists $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance}) {
#							$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} = 0;
#						}
#						$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} = $analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{distances}->{down}->{$distance} + 1;
						$distance = 0;
						$target_ctr++;
					}
				} elsif($ss == $code_ptr) {
					my $found = &check_for_code_match($taskid,$iname,$sentence_href->{$tskey},$code,$trace_detail);
					if($found) {
						if(!exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{zero_2x}) {
							$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{zero_2x} = 0;
						}
						$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{zero_2x} = $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{zero_2x} + 1;
					} else {
						if(!exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{zero}) {
							$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{zero} = 0;
						}
						$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{zero} = $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{zero} + 1;
					}
					$distance = 0;
					if($s < 0) {
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF src tskeys, same code ptr[$code_ptr] src code ct[$s]" if $trace;
					} else {
						my $temp_tskey = $c_arr->[$s];
						if(!$temp_tskey) {
							die "\t dying to fix bad temp tskey\n";
						}
						$code_ptr = $sentence_ctr{ $temp_tskey };
						$s--;
					}
				} else {
					if($s < 0) {
						## no more code value in stack
#						say "[cat:$cat][taskid:$taskid] iname[$iname} code[$code] sindex[$ss] tskey[$tskey] END OF test of [$test_code] code ptr[$code_ptr] src code ct[$s]" if $trace;
						last;
					}
					say "[cat:$cat][taskid:$taskid] iname[$iname] code[$aspect] code out of sequence [$ss] ptr[$code_ptr] at [$tskey]";
					die "\tdie to fix\n";
				}
			}
			if($target_ctr) {
				$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{counts}->{first} = $src_code_ct;
				$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{counts}->{second_dn} = $target_ctr;
				$target_code_ct = $target_ctr;
			}
		}
		say "[cat:$cat][taskid:$taskid] iname[$iname} MAKE STATS for aspect[$ktr][$aspect] aspect arr ct[".scalar(@$c_arr)."] target code ct[$target_code_ct]" if $trace_stats;
		foreach my $code (keys %$code_list) {
			my $short_dist_limit2 = 27;
			my $mid_dist_limit2 = 81;
			my $stop_pt = 0;
			my $ktr2 = 0;
			my $match_ct = 0;
			my $no_match_ct = 0;
			my $sum2 = 0; ## found creates an initial distance count
			my $short_sum2 = 0;
			my $med_sum2 = 0;
			my $large_sum2 = 0;
			my $short_ct2 = 0;
			my $med_ct2 = 0;
			my $large_ct2 = 0;
			if(exists $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}) {
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up} }) {
					if($dist eq 'zero_2x') {
						$match_ct = $match_ct + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist};
						$sum2 = $sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist};
						next;
					}
					if($dist eq 'zero') {
						$no_match_ct = $match_ct + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist};
						next;
					}
					$sum2 = $sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist};
					if($ktr2 < $stop_pt) {
						print "[cat:$cat][taskid:$taskid] dispersion [$iname][$aspect] dist[$dist] ct[".$analcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist}."] sum[$sum2]" if $trace;
					}
					if($dist < ($short_dist_limit2 + 1)) {
						$short_ct2 = $short_ct2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist};
						$short_sum2 = $short_sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct2] short sum[$short_sum2]" if $trace;
						}
					} elsif($dist < ($mid_dist_limit2 + 1)) {
						$med_ct2 = $med_ct2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist};
						$med_sum2 = $med_sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct2] med sum[$med_sum2]" if $trace;
						}
					}
					if($dist > ($mid_dist_limit2)) {
						$large_ct2 = $large_ct2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist};
						$large_sum2 = $large_sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{up}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct2] large sum[$large_sum2]" if $trace;
						}
					}
				}
				foreach my $dist (keys %{ $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down} }) {
					if($dist eq 'zero_2x') {
						$match_ct = $match_ct + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist};
						$sum2 = $sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist};
						next;
					}
					if($dist eq 'zero') {
						$no_match_ct = $match_ct + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist};
						next;
					}
					$sum2 = $sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist};
					if($ktr2 < $stop_pt) {
						print "[cat:$cat][taskid:$taskid] dispersion [$iname][$aspect] dist[$dist] ct[".$analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist}."] sum[$sum2]" if $trace_stats;
					}
					if($dist < ($short_dist_limit2 + 1)) {
						$short_ct2 = $short_ct2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist};
						$short_sum2 = $short_sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  short ct[$short_ct2] short sum[$short_sum2]" if $trace_stats;
						}
					} elsif($dist < ($mid_dist_limit2 + 1)) {
						$med_ct2 = $med_ct2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist};
						$med_sum2 = $med_sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  med ct[$med_ct2] med sum[$med_sum2]" if $trace_stats;
						}
					}
					if($dist > ($mid_dist_limit2)) {
						$large_ct2 = $large_ct2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist};
						$large_sum2 = $large_sum2 + $analcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{distances}->{down}->{$dist} * $dist;
						if($ktr2 < $stop_pt) {
							say "  large ct[$large_ct2] large sum[$large_sum2]" if $trace_stats;
						}
					}
				}
				$ktr2++;
			}
			$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{total_count} = $sum2;
			$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{match_count} = $match_ct;
			$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{no_match_count} = $no_match_ct;
			if($match_ct) {
				my $per = 10 * ($match_ct / ($match_ct + $no_match_ct));
				my $per2 = 10 * ($match_ct / $sum2);
				if($per2=~/(\d+)\.*([\d]*)/) {
					 if($1 > $overlap_thres) {
						$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_overlap} = $1;
					 }
				}
				if($per=~/(\d+)\.*([\d]*)/) {
					 if($1 >= $nesting_thres and $1 < 10) {
						$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_partial_nesting_first_in_second} = $1;
					 }
					 if($1 == 10) {
						$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_complete_nesting_first_in_second} = $1;
						my $size = 1;
						if(exists $statcodes->{$iname}->{re_aspects}->{nesting}->{complete}->{$aspect}) {
							$size = scalar(keys %{ $statcodes->{$iname}->{re_aspects}->{nesting}->{complete}->{$aspect} });
						}
						$statcodes->{$iname}->{re_aspects}->{nesting}->{complete}->{$aspect}->{$size}->{within} = $code;
						$statcodes->{$iname}->{re_aspects}->{nesting}->{complete}->{$aspect}->{$size}->{count} = $match_ct;
					 }				 
				}
				if($match_ct == $sum2) {
					$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{cat_complete_nesting_second_in_first} = 10;
					my $size = 1;
					if(exists $statcodes->{$iname}->{re_aspects}->{nesting}->{complete}->{$code}) {
						$size = scalar(keys %{ $statcodes->{$iname}->{re_aspects}->{nesting}->{complete}->{$code} });
					}
					$statcodes->{$iname}->{re_aspects}->{nesting}->{complete}->{$code}->{$size}->{within} = $aspect;
					$statcodes->{$iname}->{re_aspects}->{nesting}->{complete}->{$code}->{$size}->{count} = $match_ct;
				}
			}
			if($short_ct2) {
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{narrow}->{count} = $short_ct2;
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{narrow}->{sum} = $short_sum2;
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{narrow}->{mean} = $short_sum2 / $short_ct2;
			}
			if($med_ct2) {
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{medium}->{count} = $med_ct2;
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{medium}->{sum} = $med_sum2;
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{medium}->{mean} = $med_sum2 / $med_ct2;
			}
			if($large_ct2) {
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{wide}->{count} = $large_ct2;
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{wide}->{sum} = $large_sum2;
				$statcodes->{$iname}->{re_aspects}->{linkage}->{dispersion_updown}->{$aspect}->{$code}->{stats}->{wide}->{mean} = $large_sum2 / $large_ct2;
			}
		}					
	}
	if($ktr > 0) {
		$codes_dirty->{aspect_dispersion} = 0;
	}
	
	return $taskid;
}
sub make_aspect_list {
	my ($sentence_href,$iname,$taskid,$trace) = @_;
	
	my $s_href = {};
	foreach my $tskey (keys %$sentence_href) {
		if(exists $sentence_href->{$tskey}->{aspects} and scalar(keys %{ $sentence_href->{$tskey}->{aspects} })) {
			foreach my $code (keys %{ $sentence_href->{$tskey}->{aspects} }) {
				if($code=~/^(\d+)$/) {
					if($1 > 100) {
						## not a real code...skip
						next;
					}
				}
				my $rating = $sentence_href->{$tskey}->{aspects}->{$code};
				$s_href->{$code} = $rating;
			}
		}
	}
	return $s_href;
}

sub clean_post_recode_data {
	####
	## check and clean codes data after re_coding (data_coding file)
	##   find empty code arrays and transfer aspect coding
	####
	my ($taskid,$iname,$clean_array,$trace,$trace_more) = @_;
	my $me = "POST-RECODE-CLEAN";
	$me = $me . "][taskid:$taskid";
	my $detail_trace = 0;
	my $swap_trace = 0;
	if($trace_more) {
		$detail_trace = 1;
	}
	
	my $code_swap = {};
	if(exists $code_replacement_mapping->{code_for_code}) {
		$code_swap = $code_replacement_mapping->{code_for_code};
	}
	
	my $tcodes = undef;
	if(exists $data_coding->{$iname}->{re_codes}->{sentences}) {
		$tcodes = $data_coding->{$iname}->{re_codes}->{sentences};
	}
	if(!defined $tcodes or !scalar(keys %$tcodes)) {
		say "\t[$me] this iname[$iname] has no re_codes";
		return undef;
	}

	my $sorter = {};
	my $cctr = 0;
	foreach my $sent (keys %$tcodes) {
		if($sent=~/^t(\d+)s(\d+)/i) {
			my $t = $1;
			my $s = $2;
			$sorter->{$t}->{$s} = $sent;
			$cctr++;
		}
	}
	say "[$my_shortform_server_type][$me] iname[$iname] clean sentence sorter, [$cctr] sentences";

	my $remap = 0;
	my $fkey = undef;
	my $parsed_sent_info = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info};
	if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}) {
		$parsed_sent_info = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2};
		$remap = 1;
		$fkey = $data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_parse_key};
	}

	my $codes_up = 0;
	my $die_n_fix = 0;
	my $line_ctr = 1;
	
	foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
		## new topic...increment line count to skip topic title
		my $tkey = "t" . $tindex;
		$line_ctr++;

		foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
			my $tskey = $sorter->{$tindex}->{$sindex};
			## check for valid sentence packet...if not, skip
			if(!exists $tcodes->{$tskey}) {
				say "[$my_shortform_server_type][$me] iname[$iname] no data structure under tskey[$tskey]...skipping";
				next;
			}

			if($remap) {
				my $skey = $tskey;
				if(!$fkey) {
					say "[$my_shortform_server_type][$me] iname[$iname] data structure failure...no fkey to find remap tskeys at tskey[$skey]";
					die "\tdying to fix\n";
				}
				## check for tskey existence, if not bark error and move on
				if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey} or !$data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey}) {
					say "[$my_shortform_server_type][$me] iname[$iname] fkey[$fkey] post_coding, NOT able to remap tskey[$skey] ... no value!";
					next;
				} else {
					## check for remap existence, if not bark error and move on
					if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey}->{tskey_map}) {
						say "[$my_shortform_server_type][$me] iname[$iname] fkey[$fkey] post_coding, NOT able to remap tskey[$skey] ... no *tskey_map* key!";
						next;
					}
					## check for a valid remap value, if not bark error and move on
					if(!$data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey}->{tskey_map}) {
						say "[$my_shortform_server_type][$me] iname[$iname] fkey[$fkey] post_coding, NOT able to remap tskey[$skey] ... no *tskey_map* key value!";
						next;
					}
					## use remapped tskey
					$tskey = $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey}->{tskey_map};
				}
			}
			if(!$tskey) {
				say "\t\twhat the fuck!!! why is this null? fkey[$fkey] remap[$remap]";
				next;
			}

			## check for non-coded sentence blocks...if empty assume non-coded material
			## set to a NON-CODED block
			if(!scalar(keys %{ $tcodes->{$tskey} })) {
				$tcodes->{$tskey}->{sentence} = '_SKIP_THIS_ non coded sentence block';
				$tcodes->{$tskey}->{codes}->{101} = '_NOT_A_CODE_';
				$tcodes->{$tskey}->{aspects}->{101} = '_NOT_AN_ASPECT_';
				say "[$my_shortform_server_type][$me] [$iname] tskey[$tskey] non coded block, coded[".$tcodes->{$tskey}->{codes}->{101}."] [".$tcodes->{$tskey}->{aspects}->{101}."]...skipping";
				$codes_up = 1;
				next;
			}

			## check for non-coded sentence blocks...if aspects and codes are empty assume non-coded material
			if(!exists $tcodes->{$tskey}->{codes} or !scalar(keys %{ $tcodes->{$tskey}->{codes} })) {
				if(!exists $tcodes->{$tskey}->{aspects} or !scalar(keys %{ $tcodes->{$tskey}->{aspects} })) {
					$tcodes->{$tskey}->{sentence} = '_SKIP_THIS_ non coded sentence block';
					$tcodes->{$tskey}->{codes}->{101} = '_NOT_A_CODE_';
					$tcodes->{$tskey}->{aspects}->{_NOT_AN_ASPECT_} = 101;
					$codes_up = 1;
					say "[$my_shortform_server_type][$me] [$iname] tskey[$tskey] NO CODES or ASPECTS, non coded block, coded[".$tcodes->{$tskey}->{codes}->{101}."] [".$tcodes->{$tskey}->{aspects}->{101}."]...skipping";
					next;
				}
				print "[$me] [$iname] default codes for tskey[$tskey]]";
				my $top = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{topic};
				my $c = $data_postparse->{aquad_meta_parse}->{topic_lists_uc}->{$iname}->{$top};
				my $top_lc = $data_postparse->{aquad_meta_parse}->{topic_lists}->{$iname}->{$c};
				my $topic_main_codes = $topic_to_code_mapping->{main_codes};
				my $topic_alt_codes = $topic_to_code_mapping->{alt_codes};
				my $size = 1;
				if(exists $topic_to_code_mapping->{main_codes}->{$top_lc}) {
					my $tcode = $topic_to_code_mapping->{main_codes}->{$top_lc};
					$tcodes->{$tskey}->{codes}->{$size} = $tcode;
				}
				if(exists $topic_to_code_mapping->{alt_codes}->{$top_lc}) {
					$size++;
					my $tcode = $topic_to_code_mapping->{alt_codes}->{$top_lc};
					$tcodes->{$tskey}->{codes}->{$size} = $tcode;
				}
				foreach my $tc (keys %{$tcodes->{$tskey}->{codes}}) {
					print " c[$tc][".$tcodes->{$tskey}->{codes}->{$tc}."]";
				}
				$codes_up = 1;
				print " size[$size]\n";
#				$die_n_fix = 1;
				next;
			} else {
				foreach my $cindex (keys %{ $tcodes->{$tskey}->{codes} }) {
					my $taspect = $tcodes->{$tskey}->{codes}->{$cindex};
					if($taspect=~/^process aspect::(\d+)/i) {
						my $aspect = 'process aspect';
						$tcodes->{$tskey}->{aspects}->{$aspect} = $1;
						delete $tcodes->{$tskey}->{codes}->{$cindex};
						say "[$me] [$iname] tskey[$tskey] adding PROCESS aspect val[$1] deleting code...";
						$codes_up = 1;
					}
					if($taspect=~/^contractual aspect::(\d+)/i) {
						my $aspect = 'contractual aspect';
						$tcodes->{$tskey}->{aspects}->{$aspect} = $1;
#						$tcodes->{$tskey}->{aspects}->{ aspect} = $1;
						delete $tcodes->{$tskey}->{codes}->{$cindex};
						say "[$me] [$iname] tskey[$tskey] adding CONTRACTUAL aspect val[$1] deleting code...";
						$codes_up = 1;
					}
					if($taspect=~/^market aspect::(\d+)/i) {
						my $aspect = 'market aspect';
						$tcodes->{$tskey}->{aspects}->{$aspect} = $1;
#						$tcodes->{$tskey}->{aspects}->{ aspect} = $1;
						delete $tcodes->{$tskey}->{codes}->{$cindex};
						say "[$me] [$iname] tskey[$tskey] adding MARKET aspect val[$1] deleting code...";
						$codes_up = 1;
					}
				}
			}

			## clean bad 'procoess' aspect coding
			if(exists $tcodes->{$tskey}->{aspects} and scalar(keys %{ $tcodes->{$tskey}->{aspects} })) {
				foreach my $aspect (keys %{ $tcodes->{$tskey}->{aspects} }) {
					if($aspect=~/^procoess/i) {
						my $asp = 'process aspect';
						$tcodes->{$tskey}->{aspects}->{$asp} = $tcodes->{$tskey}->{aspects}->{$aspect};
						delete $tcodes->{$tskey}->{aspects}->{$aspect};
					}
					if($aspect=~/^process$/i) {
						delete $tcodes->{$tskey}->{aspects}->{$aspect};
					}
					if($aspect=~/^\d+$/i) {
						delete $tcodes->{$tskey}->{aspects}->{101};
						$tcodes->{$tskey}->{aspects}->{_NOT_AN_ASPECT_} = 101;
					}
				}
			}
#			if($tskey=~/^t40s7/i) {
#				say "......pre 2 pre [$iname][$tskey] codes ct[".scalar(keys %{ $tcodes->{$tskey}->{codes} })."]";
#			}
			if(exists $data_postparse->{post_parse}->{$iname}->{codes}) {
				if(exists $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}) {
					if(exists $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}) {
						if(exists $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{aspects}) {
							foreach my $aspect (keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{aspects} }) {
								delete $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{aspects}->{$aspect};
							}
							delete $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{aspects};
						}
						if(exists $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes}) {
							foreach my $aspect (keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes} }) {
								delete $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes}->{$aspect};
							}
							delete $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey}->{codes};
						}
						delete $data_postparse->{post_parse}->{$iname}->{codes}->{sentences}->{$tskey};
					}
					if(!scalar(keys %{ $data_postparse->{post_parse}->{$iname}->{codes}->{sentences} })) {
						delete $data_postparse->{post_parse}->{$iname}->{codes}->{sentences};
						$codes_dirty->{post_coding} = 1;
					}
				}
				if(!scalar(keys %{ $data_postparse->{post_parse}->{$iname}->{codes} })) {
					delete $data_postparse->{post_parse}->{$iname}->{codes};
				}
			}

			if(exists $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}) {
				if(exists $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} and scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} })) {
					#say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] sorter size[".scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} })."]";
					foreach my $_code (keys %{ $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} }) {
						delete $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes}->{$_code};
					}
				}
			}

			## match and sort codes
			if(exists $tcodes->{$tskey}->{codes} and scalar(keys %{ $tcodes->{$tskey}->{codes} })) {
				foreach my $cindex (keys %{ $tcodes->{$tskey}->{codes} }) {
					my $_code = $tcodes->{$tskey}->{codes}->{$cindex};
					if($_code=~/^energy manage/i) {
#						say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] index[$cindex] ..sorting...pre-swap check[".$_code."] swapsize[".scalar(keys %{ $code_swap })."]";
					}
					if($_code=~/audit/i) {
						say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] index[$cindex] ..audit sorting...pre-swap check[".$_code."] swapsize[".scalar(keys %{ $code_swap })."]";
					}
					if(scalar(keys %{ $code_swap })) {
						if(exists $code_swap->{$_code}) {
							my $remove = 0;
							if(exists $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes}->{$_code}) {
								delete $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes}->{$_code};
								$remove = 1;
							}
							say "[$me] [$iname] tskey[$tskey] swapping[$_code] for [".$code_swap->{$_code}."] removing code [$remove]..." if $swap_trace;
#							$_code = $code_swap->{$_code};
							$data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes}->{ $code_swap->{$_code} } = 1;
							if($_code=~/energy/i) {
								say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] index[$cindex] ..sorting XXX codes[".$_code."] swap[".$code_swap->{$_code}."]";
							}
							if($code_swap->{$_code}=~/^energy/i) {
								say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] index[$cindex] ..swapped XXX codes[".$_code."] swap[".$code_swap->{$_code}."]";
							}
						} else {
							if($_code=~/energy manage/i) {
#								say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] index[$cindex] ..NO swap code[".$_code."] swap[]";
							}
							$data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes}->{$_code} = 1;
						}
					} else {
						$data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes}->{$_code} = 1;
					}
				}
			}
			
			## if sorted codes...add to final_codes 
			if(exists $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}) {
				if(exists $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} and scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} })) {
					$data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{final_codes} = undef;
					$data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{final_codes} = {};
					foreach my $_code (keys %{ $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} }) {
						my $size = 1;
#						if($_code=~/^energy manage/i) {
#							say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] setting to final codes[".$_code."] index[$size] sortsize[".scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} })."]";
#							if(!exists $code_swap->{$_code}) {
#								say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] final codes...cannot find code[".$_code."] in swap array!!!";
#							$_code = $code_swap->{$_code};
#							} else {
#								say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] final codes... code[".$_code."] in swap array[".$code_swap->{$_code}."]";
#							}
#						}
#						if($_code=~/^energy::energy management::audits/i) {
#							say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] setting to FINAL codes[".$_code."] index[$size] sortsize[".scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sorter}->{$tskey}->{codes} })."]";
#						}
						if(exists $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{final_codes}) {
							$size = scalar(keys %{ $data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{final_codes} });
							$size++;
						}						
						if($_code=~/^_NOT_A_CODE_$/i) {
							$size = 101;
						}
						if(exists $code_swap->{$_code}) {
							$_code = $code_swap->{$_code};
						}
#						if($_code=~/^energy manage/i) {
#							say "[$my_shortform_server_type][$me][$iname] tskey[$tskey] index[$size] ..final codes with swap[".$_code."]";
#						}
						$data_coding->{$iname}->{re_codes}->{sentences}->{$tskey}->{final_codes}->{$size} = $_code;
					}
				}
			}
			
			## copy last sentence over...no error check
			$tcodes->{$tskey}->{sentence} = $parsed_sent_info->{$tskey}->{sentence};
			
			$run_status->{active_coding_iname_verify_TOGOFF}->{$iname} = 1;
			if(!exists $run_status->{active_coding_iname_verify_TOGOFF}->{$iname} or !$run_status->{active_coding_iname_verify_TOGOFF}->{$iname}) {
				## do some verify'in...check for a viable sentences
				my $_s_c = $tcodes->{$tskey}->{sentence};
				if(exists $run_status->{verify_sentences_parsing_coding} and $run_status->{verify_sentences_parsing_coding}) {
					if(!exists $parsed_sent_info->{$tskey}->{sentence}) {
						say "[$me] coding and parsing sentences do not match at iname[$iname] tskey[$tskey]...fix to continue";
						say "\t parsed sentenced does not exist! -> coded[$_s_c]";
						die "\tdying...this is too hard!\n";
					}
					my $_s_p = $parsed_sent_info->{$tskey}->{sentence};
					my $_l_s_c = length($_s_c);
					my $_l_s_p = length($_s_p);
					if(!$_l_s_c) {
						say "[$me] [$iname] coding sentence is blank at tskey[$tskey]...forcing copy parse to coding";
						$tcodes->{$tskey}->{sentence} = $parsed_sent_info->{$tskey}->{sentence};
						$codes_up = 1;
					} elsif($_l_s_p > 10) {
						if($_l_s_p != $_l_s_c) {
							if(($_l_s_p - $_l_s_c) > $test_extra_chars) {
								say "[$me] coding and parsing+ sentences do not match at iname[$iname] tskey[$tskey]...fix to continue";
								say "\t parsed[$_s_p] coded[$_s_c]";
								$tcodes->{$tskey}->{sentence} = $parsed_sent_info->{$tskey}->{sentence};
#								die "\tdying...this is too hard!\n";
							}
							if(($_l_s_c - $_l_s_p) > $test_extra_chars) {
								say "[$me] coding+ and parsing sentences do not match at iname[$iname] tskey[$tskey]...fix to continue";
								say "\t parsed[$_s_p] coded[$_s_c]";
								die "\tdying...this is too hard!\n";
							}
							if(exists $run_status->{force_sentence_copy_parsing_to_coding} and $run_status->{force_sentence_copy_parsing_to_coding}) {
								say "[$me] coding and parsing sentences do not match at iname[$iname] tskey[$tskey]...forcing copy parse to coding";
								say "\t parsed[$_s_p] coded[$_s_c]";
								$tcodes->{$tskey}->{sentence} = $parsed_sent_info->{$tskey}->{sentence};
								$codes_up = 1;
							}
						}
					} else {
						if($_s_p eq $_s_c) {
						} else {
							if(exists $run_status->{force_sentence_copy_parsing_to_coding} and $run_status->{force_sentence_copy_parsing_to_coding}) {
								say "[$me] coding and parsing sentences do not match at iname[$iname] tskey[$tskey]...forcing copy parse to coding";
								say "\t parsed[$_s_p] coded[$_s_c]";
								$tcodes->{$tskey}->{sentence} = $parsed_sent_info->{$tskey}->{sentence};
								$codes_up = 1;
							} else {
								say "[$me] coding and parsing sentences do not match at iname[$iname] tskey[$tskey]...fix to continue";
								say "\t parsed[$_s_p] coded[$_s_c]";
								die "\tdying...this is too hard!\n";
							}
						}
					}
				} else {
					## if the sentence text has not been import to data_coding...do so now
					if(!exists $tcodes->{$tskey}->{sentence}) {
						$tcodes->{$tskey}->{sentence} = $parsed_sent_info->{$tskey}->{sentence};
						$codes_up = 1;
					}
				}
			}
			
			if(!exists $tcodes->{$tskey}->{codes}) {
				say "[$me] [$iname] codes hash for tskey[$tskey]]...does not exist...fix to continue";
				#say "\t parsed[$_s_p] coded[$_s_c]";
				die "\tdying...this is too hard! line[".__LINE__."]\n";
			} elsif(!scalar(keys %{ $tcodes->{$tskey}->{codes} })) {
#				say "[$me] [$iname] codes hash for tskey[$tskey]]...is empty!! prev[$code_count] ind[$code_ind] prev2[$code_count] ind[$code_ind] prev3[$code_count3] ind[$code_ind3] sorted[$sorted] exist...fix to continue";
				say "[$me] [$iname] codes hash for tskey[$tskey]]...is empty!! does not exist...fix to continue";
				$die_n_fix = 1;
				die "\tdying...this is too hard! line[".__LINE__."]\n";
			}
			if($tskey=~/^t40s7/i and $iname=~/^G0/i) {
#				$die_n_fix = 1;
			}
		}
	}
	
	if($codes_up) {
		$codes_dirty->{re_codes} = 1;
	}
	if($die_n_fix) {
#		die "\tdying...too many hash fixes[$die_n_fix]...this is too hard!\n";
		return 0;
	}

	return 1;
}
sub make_post_recode_stats {
	####
	## make counts and sums for codes after re_coding (data_coding file)
	####
	my ($taskid,$iname,$clean_array,$trace,$trace_more) = @_;
	my $me = "POST-RECODE-STATS";
	$me = $me . "][taskid:$taskid";
	my $detail_trace = 0;
	if($trace_more) {
		$detail_trace = 1;
	}
	
	
	my $tcodes = undef;
	if(exists $data_coding->{$iname}->{re_codes}->{sentences}) {
		$tcodes = $data_coding->{$iname}->{re_codes}->{sentences};
	}
	if(!defined $tcodes or !scalar(keys %$tcodes)) {
		say "\t[$me] this iname[$iname] has no re_codes";
		return undef;
	}

	my $sorter = {};
	my $cctr = 0;
	foreach my $sent (keys %$tcodes) {
		if($sent=~/^t(\d+)s(\d+)/i) {
			my $t = $1;
			my $s = $2;
			$sorter->{$t}->{$s} = $sent;
			$cctr++;
		}
	}
	say "[$my_shortform_server_type][$me] iname[$iname] post sentence sorter, [$cctr] sentences";

	if(!exists $post_text_config->{critical_text_low_limit}) {
		say "[$me] what up dog...critical text value is missing [".$post_text_config->{critical_text_low_limit}."]";
		die;
	}

	my $remap = 0;
	my $fkey = undef;
	my $parsed_sent_info = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info};
	if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}) {
		$parsed_sent_info = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2};
		$remap = 1;
		$fkey = $data_postparse->{aquad_meta_parse}->{profile}->{$iname}->{file}->{src_parse_key};
	}

	## clear code stats...retain nothing
	if(exists $data_post_coding->{post_coding}->{$iname} and scalar(keys %{ $data_post_coding->{post_coding}->{$iname} })) {
#		$data_post_coding->{post_coding}->{$iname}->{code_stats} = undef;
		$data_post_coding->{post_coding}->{$iname} = undef;
		say "[$my_shortform_server_type][$me] iname[$iname] cleared code stats for this iname";
	}
	
	my $update_data_coding = 0;
	my $line_ctr = 1;
	foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
		## new topic...increment line count to skip topic title
		$line_ctr++;

		foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
			my $tskey = $sorter->{$tindex}->{$sindex};

			## if clean_array set, then check for empty code hash, delete stuff, and skip
			if($clean_array) {
				if(!scalar(keys %{ $tcodes->{$tskey}->{codes} }) and !$tcodes->{$tskey}->{sentence}) {
					## delete stuff....and move on...
					delete $tcodes->{$tskey}->{sentence};
					$tcodes->{$tskey}->{codes} = undef;
					delete $tcodes->{$tskey}->{codes};
					$tcodes->{$tskey} = undef;
					delete $tcodes->{$tskey};
					next;
				}
			}
			
			if($remap) {
				my $skey = $tskey;
				if(!$fkey) {
					say "[$my_shortform_server_type][$me] iname[$iname] data structure failure...no fkey to find remap tskeys at tskey[$skey]";
					die "\tdying to fix\n";
				}
				## check for tskey existence, if not bark error and move on
				if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey} or !$data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey}) {
					say "[$my_shortform_server_type][$me] iname[$iname] fkey[$fkey] post_coding, NOT able to remap tskey[$skey] ... no value!";
					next;
				} else {
					## check for remap existence, if not bark error and move on
					if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey}->{tskey_map}) {
						say "[$my_shortform_server_type][$me] iname[$iname] fkey[$fkey] post_coding, NOT able to remap tskey[$skey] ... no *tskey_map* key!";
						next;
					}
					## check for a valid remap value, if not bark error and move on
					if(!$data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey}->{tskey_map}) {
						say "[$my_shortform_server_type][$me] iname[$iname] fkey[$fkey] post_coding, NOT able to remap tskey[$skey] ... no *tskey_map* key value!";
						next;
					}
					## use remapped tskey
					$tskey = $data_postparse->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$skey}->{tskey_map};
				}
			}
			if(!$tskey) {
				say "\t\twhat the fuck!!! why is this null? fkey[$fkey] remap[$remap]";
				next;
			}
			## if re-code tskey sentence hash is empty, delete hash and move on.
			if(!scalar(keys %{ $tcodes->{$tskey} })) {
				$tcodes->{$tskey} = undef;
				delete $tcodes->{$tskey};
				next;
			}
			

			$line_ctr++;
			my $fail_ct = 0;
			my $start_char = 0;
			if(exists $parsed_sent_info->{$tskey}->{begin}->{chars} and $parsed_sent_info->{$tskey}->{begin}->{chars}) {
				$start_char = $parsed_sent_info->{$tskey}->{begin}->{chars};
			} else {
				## say error
				say "\t[$my_shortform_server_type][$me] iname[$iname] post_parse sent[$tskey] has no start chars[". $parsed_sent_info->{$tskey}->{begin} . "] begin ct[".scalar(keys %{ $parsed_sent_info->{$tskey}->{begin} })."]";
				$fail_ct++;
			}
			my $line_count = 0;
			if(exists $parsed_sent_info->{$tskey}->{counts}->{ts_total_lines} and $parsed_sent_info->{$tskey}->{counts}->{ts_total_lines}) {
				$line_count = $parsed_sent_info->{$tskey}->{counts}->{ts_total_lines};
			} elsif(exists $parsed_sent_info->{$tskey}->{counts}->{lines} and $parsed_sent_info->{$tskey}->{counts}->{lines}) {
				$line_count = $parsed_sent_info->{$tskey}->{counts}->{lines};
			} else {
				## say error
				say "\t[$my_shortform_server_type][$me] iname[$iname] post_parse lines is null at tskey[$tskey] has no counts[". $parsed_sent_info->{$tskey}->{counts} . "] cts[".scalar(keys %{ $parsed_sent_info->{$tskey}->{counts} })."]";
				$fail_ct++;
			}
			my $char_count = 0;
			if(defined $parsed_sent_info->{$tskey}->{sentence} and length($parsed_sent_info->{$tskey}->{sentence})) {
				$char_count = length($parsed_sent_info->{$tskey}->{sentence});
#				next;
			} else {
				## say error
				say "\t[$my_shortform_server_type][$me] iname[$iname] not able to locate sentence text for tskey[$tskey]!";
				$fail_ct++;
			}
			if($fail_ct > 1) {
				say "\t[$my_shortform_server_type][$me] iname[$iname] multiple lookup fails...[$tskey] sentence array my need cleansing!";
			}
			my $_s_parse = $parsed_sent_info->{$tskey}->{sentence};

			## remove legacy keys - not needed anymore
			if(exists $tcodes->{$tskey}->{overall_char_begin}) {
				delete $tcodes->{$tskey}->{overall_char_begin};
			}
			if(exists $tcodes->{$tskey}->{begin_char_ct}) {
				delete $tcodes->{$tskey}->{begin_char_ct};
			}

			my $postcode_chars = $char_count;
			if(exists $parsed_sent_info->{$tskey}->{counts}->{chars}) {
				if($char_count != $parsed_sent_info->{$tskey}->{counts}->{chars}) {
					say "\t[$my_shortform_server_type][$me] iname[$iname] tskey[$tskey] stashed char ct[".$parsed_sent_info->{$tskey}->{counts}->{chars}."] is wrong actual ct[$postcode_chars]...resetting";
					$parsed_sent_info->{$tskey}->{counts}->{chars} = $postcode_chars;
				}
			}
			my $postcode_words = 1;
			my $_s_c = $tcodes->{$tskey}->{sentence};
			## check for char length over 2, with at least 1 space to split into words
			if($postcode_chars > 2 and $_s_parse=~/\s+/) {
				my @p = split /[\s+]/,$_s_parse;
				$postcode_words = scalar(@p);
			}
			if(exists $parsed_sent_info->{$tskey}->{counts}->{words}) {
				if($postcode_words > 1 and $postcode_words != $parsed_sent_info->{$tskey}->{counts}->{words}) {
					say "\t[$my_shortform_server_type][$me] iname[$iname] tskey[$tskey] stashed WORD ct[".$parsed_sent_info->{$tskey}->{counts}->{words}."] is wrong actual ct[$postcode_words]...resetting";
					$parsed_sent_info->{$tskey}->{counts}->{words} = $postcode_words;
				}
			}
			my $postcode_lines = 1;
			if($postcode_lines != $line_count) {
				## check if defined before carping...no sense barking about older data structures
				if(defined $parsed_sent_info->{$tskey}->{counts}->{ts_total_lines}) {
					say "\t[$my_shortform_server_type][$me] iname[$iname] tskey[$tskey] stashed LINE ct[".$parsed_sent_info->{$tskey}->{counts}->{ts_total_lines}."] is wrong actual ct[$postcode_lines]...resetting to 1";
				}
				$parsed_sent_info->{$tskey}->{counts}->{ts_total_lines} = $postcode_lines;
			}
			## sanity check, if not sane, set to falsy...
			if(!$postcode_words or !$postcode_chars) {
				$postcode_lines = 0;
			}
			if($postcode_lines=~/HASH/ or $postcode_words=~/HASH/ or $postcode_chars=~/HASH/) {
				say "[$me] ERROR setting char/work/line values for tskey[$tskey] iname[$iname]";
				die "\tdying to fix at [".__LINE__."]\n";
			}

			## loop over codes for sentence
			foreach my $cindex (keys %{$tcodes->{$tskey}->{codes}}) {
				## get codes from possible embedded code tree
				if($cindex > 100) {
					## not a real code...skip
					next;
				}
				my $codetree = $tcodes->{$tskey}->{codes}->{$cindex};
				$codetree =~ s/::/___/g;
#				my $clayers = &make_code_layers($codetree,$iname,$taskid,$trace);
#				if(scalar(keys %$clayers) > 1) {
#					say"[$me] iname[$iname] clayers > 1...base code[".$clayers->{1}."] 2[".$clayers->{2}."]" if $detail_trace;
#				}
#				foreach my $lindex (keys %$clayers) {
					my $code = $codetree;
#					my $code = $clayers->{$lindex};
##					data_post_coding
					if(!exists $codectrhref->{$code}) {
						## if code is new, initialize code in counter array
						$codectrhref->{$code} = 0;
					}
					$codectrhref->{$code}++;
					## set line, word, char counts in post_coding
					if(!exists $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{words}->{total}->{count}) {
						$data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{words}->{total}->{count} = 0;
					}
					$data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{words}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{words}->{total}->{count} + $postcode_words; 
					if(!exists $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{lines}->{total}->{count}) {
						$data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{lines}->{total}->{count} = 0;
					}
					$data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{lines}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{lines}->{total}->{count} + $postcode_lines; 
					if(!exists $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{chars}->{total}->{count}) {
						$data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{chars}->{total}->{count} = 0;
					}
					$data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{chars}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{chars}->{total}->{count} + $postcode_chars; 

					if($data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{chars}->{total}->{count}=~/HASH/ or $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{words}->{total}->{count}=~/HASH/ or $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{lines}->{total}->{count}=~/HASH/) {
						say "[$me] ERROR setting char/work/line values for tskey[$tskey] iname[$iname] code[$code]";
						die "\tdying to fix at [".__LINE__."]\n";
					}
#				}

			}
			## loop over aspects for sentence
			my $aspects_words = 0;
			my $aspects_ratings = 0;
			my $aspects_5_words = 0;
			my $aspects_5_ratings = 0;
			my $aspects_4_words = 0;
			my $aspects_4_ratings = 0;
			my $tog_at_3 = 0;
			foreach my $aspect (keys %{$tcodes->{$tskey}->{aspects}}) {
				## get codes from possible embedded code tree
				if($aspect=~/^_NOT_AN_ASPECT_$/) {
					## not a real aspect code...skip
					next;
				}
				if(!exists $aspectctrhref->{$aspect}) {
					## if code is new, initialize code in counter array
					$aspectctrhref->{$aspect} = 0;
				}
				$aspectctrhref->{$aspect}++;

				my $rating = $tcodes->{$tskey}->{aspects}->{$aspect};
				if($rating > 2) { $tog_at_3 = 1; }
				## set line, word, char counts in post_coding
				if(!exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total}->{count} + $postcode_words;
				$aspects_words = $aspects_words + $postcode_words;
				if(!exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{chars}->{total}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{chars}->{total}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{chars}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{chars}->{total}->{count} + $postcode_chars;
				if(!exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{lines}->{total}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{lines}->{total}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{lines}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{lines}->{total}->{count} + $postcode_lines;
				if(!exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total}->{count} + $rating;
				$aspects_ratings = $aspects_ratings + $rating;
				if($rating == 4) {
					$aspects_4_words = $aspects_4_words + $postcode_words;
					$aspects_4_ratings = $aspects_4_ratings + $rating;
					if(!exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_4}->{count}) {
						$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_4}->{count} = 0;
					}
					$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_4}->{count} = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_4}->{count} + $rating;
					if(!exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_4}->{integral_sum}) {
						$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_4}->{integral_sum} = 0;
					}
					$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_4}->{integral_sum} = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_4}->{integral_sum} + $postcode_words;
				}
				if($rating == 5) {
					$aspects_5_words = $aspects_5_words + $postcode_words;
					$aspects_5_ratings = $aspects_5_ratings + $rating;
					if(!exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_5}->{count}) {
						$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_5}->{count} = 0;
					}
					$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_5}->{count} = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_5}->{count} + $rating;
					if(!exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_5}->{integral_sum}) {
						$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_5}->{integral_sum} = 0;
					}
					$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_5}->{integral_sum} = $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_5}->{integral_sum} + $postcode_words;
				}
			}
			if($aspects_ratings) {
				if(!exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total}->{count} + $aspects_ratings;
				if(!exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratings}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratings}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratings}->{count} = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratings}->{count} + $aspects_5_ratings;
				if(!exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratings}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratings}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratings}->{count} = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratings}->{count} + $aspects_4_ratings;
				if(exists $post_text_config->{critical_text_low_limit} and $post_text_config->{critical_text_low_limit}) {
					if($tog_at_3) {

						if($aspects_ratings > $post_text_config->{critical_text_low_limit}) {
							my $akey = $iname . "__" . $tskey;
							$data_post_coding->{aquad_meta_coding}->{all_inames}->{critical_list}->{$akey} = $aspects_ratings;
#							say "[$me] [$iname] ...akey[$akey] rating[".$data_post_coding->{aquad_meta_coding}->{all_inames}->{critical_list}->{$akey}.":$aspects_ratings]";
						}
					}
				}
			}
			if($aspects_words) {
				if(!exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total}->{integral_sum}) {
					$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total}->{integral_sum} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total}->{integral_sum} = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total}->{integral_sum} + $aspects_words;
				if(!exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{words}->{integral_sum}) {
					$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{words}->{integral_sum} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{words}->{integral_sum} = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{words}->{integral_sum} + $aspects_5_words;
				if(!exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{words}->{integral_sum}) {
					$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{words}->{integral_sum} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{words}->{integral_sum} = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{words}->{integral_sum} + $aspects_4_words;
			}
			foreach my $cindex (keys %{$tcodes->{$tskey}->{final_codes}}) {
				## get codes from possible embedded code tree
				if($cindex > 100) {
					## not a real code...skip
					next;
				}
				my $codetree = $tcodes->{$tskey}->{final_codes}->{$cindex};
				$codetree =~ s/::/___/g;
				my $code = $codetree;
				if(!exists $final_codectrhref->{$code}) {
					## if code is new, initialize code in counter array
					$final_codectrhref->{$code} = 0;
				}
				$final_codectrhref->{$code}++;

				## set line, word, char counts in post_coding
				if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count} + $postcode_words; 
				if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count} + $postcode_lines; 
				if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count} + $postcode_chars; 

				if($data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count}=~/HASH/ or $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count}=~/HASH/ or $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count}=~/HASH/) {
					say "[$me] ERROR setting char/work/line values for tskey[$tskey] iname[$iname] code[$code]";
					die "\tdying to fix at [".__LINE__."]\n";
				}
			}
			foreach my $cindex (keys %{$tcodes->{$tskey}->{final_codes}}) {
				## get codes from possible embedded code tree
				if($cindex > 100) {
					## not a real code...skip
					next;
				}
				my $codetree = $tcodes->{$tskey}->{final_codes}->{$cindex};
				my $clayers = &make_code_layers($codetree,$iname,$taskid,$trace);
				my $top_code = $codetree;
				$top_code =~ s/::/___/g;

				$data_coding->{runlinks}->{code_form_mapping}->{$top_code} = $codetree;
				$data_coding->{runlinks}->{code_tree_base}->{$top_code} = $clayers->{1};

				my $top = 1;
#				if(scalar(keys %$clayers) == 1) {
#				if(!exists $prime_codectrhref->{ $clayers->{1} }) {
#					$prime_codectrhref->{ $clayers->{1} } = 0;
#				}
#				$prime_codectrhref->{ $clayers->{1} }++;
#				}
				if(scalar(keys %$clayers) > 1) {
					$nested_codectrhref->{$top_code} = $codetree;
				}
				if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$top_code}->{lines}->{tbase}->{count} or !$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$top_code}->{lines}->{tbase}->{count}) {
					say"[$me] [$iname] tskey[$tskey] topcode missing tbase value[$top_code] [".$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$top_code}->{lines}->{tbase}->{count}."]";
					die "\tdying to fix codetree[$codetree] at line[".__LINE__."]\n";
				}
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$top_code}->{lines}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$top_code}->{lines}->{tbase}->{count};

				my ($lines,$words,$chars) = (0,0,0);
				my $prev_index = -1;
				foreach my $lindex (sort {$b <=> $a} keys %$clayers) {
					my $code = $clayers->{$lindex};
#					if($code=~/^$top_code$/) {
					if($top and ($code ne $top_code)) {
						say"[$me] [$iname] tskey[$tskey] topcode ORDER mismatch[$top_code][$code] top[$top] lindex[$lindex] prev_index[$prev_index] final code[".$clayers->{1}."] ";
						die "\tdying to fix at line[".__LINE__."]\n";
					}
					if($code eq $top_code) {
						## top code settings
						if(!$top) {
							say"[$me] [$iname] tskey[$tskey] topcode ORDER mismatch[$top_code][$code] top[$top] lindex[$lindex] prev_index[$prev_index] final code[".$clayers->{1}."] ";
							die "\tdying to fix at line[".__LINE__."]\n";
						}
						$top = 0;
						$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count};
						$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count};
						$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count};
						next;
					}
					$top = 0;
					$prev_index = $lindex;


				}
			}
		}
	}
	foreach my $top_code (keys %$nested_codectrhref) {
#		$nested_codectrhref->{$codetree} = 1;
		my $codetree = $nested_codectrhref->{$top_code};
		my $clayers = &make_code_layers($codetree,$iname,$taskid,$trace);
#		my $top_code = $codetree;
#		$top_code =~ s/::/___/g;

		if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$top_code}) {
			## code is not present with this iname...skip
			say "[$me] [$iname] topcode[$top_code] does not exist in this iname...skipping  " if $detail_trace;
			next;
		}
		
		if(!scalar(keys %$clayers) > 1) {
			say"[$me] iname[$iname] clayers > 1...base final code[".$clayers->{1}."] 2[".$clayers->{2}."]" if $detail_trace;
			die "\tcodetree[$codetree] is broke!\n";
		}
		my $top = 1;
		my ($lines,$words,$chars) = (0,0,0);
		foreach my $lindex (sort {$b <=> $a} keys %$clayers) {
			my $code = $clayers->{$lindex};
			if($top) {
				$lines = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count};
				$words = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count};
				$chars = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count};
				$top = 0;
				if(!$lines) {
					say "[$me] [$iname] top code[$code] has no lines, ct[".$clayers->{1}."] tbase[".$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$top_code}->{lines}->{tbase}->{count}."]";
					die "\tcodetree[$codetree] is broke!\n";
				}
				
				next;
			}
			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{nested}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{nested}->{count} = 0;
			}
			$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{nested}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{nested}->{count} + $lines;
			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{nested}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{nested}->{count} = 0;
			}
			$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{nested}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{nested}->{count} + $words;
			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{nested}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{nested}->{count} = 0;
			}
			$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{nested}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{nested}->{count} + $chars;
					
			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count} = 0;
			}
			$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count} + $lines;
			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count} = 0;
			}
			$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count} + $words; 
			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} = 0;
			}
			$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} + $chars; 

			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count} = 0;
			}
			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count} = 0;
			}
			if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count}) {
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count} = 0;
			}
					
			say "[$me] iname[$iname] is base for final code group[".$code."] lines[".$lines."] words[$words]" if $detail_trace;
		}
	}
	say "[$my_shortform_server_type][$me] iname[$iname] code ct[".scalar(keys %{ $data_post_coding->{post_coding}->{$iname}->{code_stats} })."]";
	
	$codes_dirty->{post_coding} = 1;
	if($update_data_coding) {
		$codes_dirty->{re_codes} = 1;
	}
	return $taskid;
}
sub make_summary_post_recode_stats {
	####
	## make summary counts and sums for ALL inames and codes after re_coding (data_coding file)
	####
	my ($taskid,$trace,$trace_more) = @_;
	my $me = "POST-RECODE-SUMMARY";
	$me = $me . "][taskid:$taskid";
	
	## clear codes from all_inames
	$data_post_coding->{aquad_meta_coding}->{all_inames} = {};
	my %max_codes = ();
	my %base_codes = ();

	if(scalar(keys %$codectrhref)) {
		##
		## if new codes, replace all codes in meta_coding...does not make sense to add more to existing values....
		##
		foreach my $code (keys %$codectrhref) {
			if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{chars}->{total}->{count}) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{chars}->{total}->{count} = 0;
			}
			if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{words}->{total}->{count}) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{words}->{total}->{count} = 0;
			}
			if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{lines}->{total}->{count}) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{lines}->{total}->{count} = 0;
			}
			my ($lines,$words,$chars) = (0,0,0);
			foreach my $iname (keys %{ $data_post_coding->{post_coding} }) {
				if(exists $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code} ) {
					if(defined $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{chars}->{total}->{count}) {
						$chars = $chars + $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{chars}->{total}->{count};
					}
					if(defined $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{words}->{total}->{count}) {
						$words = $words + $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{words}->{total}->{count};
					}
					if(defined $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{lines}->{total}->{count}) {
						$lines = $lines + $data_post_coding->{post_coding}->{$iname}->{pre_code_stats}->{$code}->{lines}->{total}->{count};
					}
				}
			}
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{chars}->{total}->{count} = $chars;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{words}->{total}->{count} = $words;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_per_code_stats}->{$code}->{lines}->{total}->{count} = $lines;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{pre_code_list}->{$code} = $lines;
		}
		say "[$my_shortform_server_type][$me] all inames, code ct[".scalar(keys %{ $codectrhref })."]";
	}
	if(scalar(keys %$final_codectrhref)) {
		##
		## if new codes, replace all codes in meta_coding...does not make sense to add more to existing values....
		##
		foreach my $code (keys %$final_codectrhref) {
			my $base_code = undef;
			if($code=~/___/) {
				my @pts = split "___",$code;
				if(!scalar(@pts)) {
					die "\t[$me]...what the hell....splitting[$code] broke at line[".__LINE__."]\n";
				}
				$base_code = $pts[0];
				$base_codes{$base_code} = 1;
			}
			if($base_code) {
				my $re_code = $code;
				$re_code =~ s/___/::/g;
				my $clayers = &make_code_layers($re_code,undef,$taskid,$trace);
				my $found = 0;
				my $size = scalar(keys %$clayers);
				foreach my $lindex (sort {$b <=> $a} keys %$clayers) {
					if($code eq $clayers->{$lindex}) {
						$found = $lindex;
					}
				}
				if(!$found) {
					die "[$me] bad found at [".__LINE__."]\n";
				}
				if($found != $size) {
					die "[$me] bad size[$size] and found[$found] at [".__LINE__."]\n";
				}
				foreach my $iname (keys %{ $data_post_coding->{post_coding} }) {
					if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code} ) {
						## code does not exist..
						next;
					}
					my $ctr = 1;
					my $chars = 0;
					my $words = 0;
					my $lines = 0;
					for (my $i=$size; $i>0; $i--) {
						my $_code = $clayers->{$i};
						my $b_code = $_code;
						$b_code =~ s/___/::/g;
						$data_coding->{runlinks}->{code_form_mapping}->{$_code} = $b_code;
						if(!exists $data_coding->{runlinks}->{code_tree_base}->{$_code}) {
							say "[$me] Nested Codes: ADDING code tree base to[$code] base_code[".$clayers->{1}."]" if $trace;
							$data_coding->{runlinks}->{code_tree_base}->{$_code} = $base_code;
						}
						$max_codes{$_code} = 1;
						if(!$lines) {
							if($code ne $_code) {
								say "[$me][$iname] bad mojo at code[$code] mismatch to [$_code]";
								die "\t fix yer mess at [".__LINE__."]\n";
							}
							if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$_code}->{lines}->{tbase} ) {
								say "[$me][$iname] bad mojo at code[$code] NO tbase value!!!";
								die "\t fix yer mess at [".__LINE__."]\n";
							}
							$lines = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$_code}->{lines}->{tbase}->{count};
							$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{lines}->{tbase}->{count} = $lines;
							if(!$lines) { last; } ## no tbase value for code
							$words = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$_code}->{words}->{tbase}->{count};
							$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{words}->{tbase}->{count} = $words;
							$chars = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$_code}->{chars}->{tbase}->{count};
							$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{chars}->{tbase}->{count} = $chars;
						} else {
							my $subtree = 0;
							if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{lines}->{subtree}) {
								$subtree = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{lines}->{subtree}->{count};
							}
							$subtree = $lines + $subtree;
							if($subtree) {
								$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{lines}->{subtree}->{count} = $subtree;
							}
							$subtree = 0;
							if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{words}->{subtree}) {
								$subtree = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{words}->{subtree}->{count};
							}
							$subtree = $words + $subtree;
							if($subtree) {
								$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{words}->{subtree}->{count} = $subtree;
							}
							$subtree = 0;
							if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{chars}->{subtree}) {
								$subtree = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{chars}->{subtree}->{count};
							}
							$subtree = $chars + $subtree;
							if($subtree) {
								$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$_code}->{chars}->{subtree}->{count} = $subtree;
							}
						}
#						$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$base_code}->{lines}->{info2}->{$code}->{$_code} = "ictr" . $ctr . "|i" . $i . "|l-" . $lines;
						$ctr++;
					}
				}
			} else {
				$max_codes{$code} = 1;
				$data_coding->{runlinks}->{code_form_mapping}->{$code} = $code;
				foreach my $iname (keys %{ $data_post_coding->{post_coding} }) {
					if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code} ) {
						## code does not exist..
						next;
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}) {
						$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{tbase}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}) {
						$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{tbase}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}) {
						$data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{tbase}->{count};
					}
				}
			}
		}

		foreach my $code (keys %max_codes) {
			my $base_code = undef;
			if($code=~/___/) {
				my @pts = split "___",$code;
				if(!scalar(@pts)) {
					die "\t[$me]...what the hell....splitting[$code] broke at line[".__LINE__."]\n";
				}
				$base_code = $pts[0];
			}
			if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count} = 0;
			}
			if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count} = 0;
			}
			if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}->{count} = 0;
			}
			my $base_iname_ctr = 0;
			my $sub_iname_ctr = 0;
			foreach my $iname (keys %{ $data_post_coding->{post_coding} }) {
				if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code} ) {
					## code does not exist..
					next;
				}
				my $chars = 0;
				my $words = 0;
				my $_code = $code;
				my $lines = 0;
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase} ) {
					$lines = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if($lines) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count} + $lines;
					$base_iname_ctr++;
				}
				$lines = 0;
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree} ) {
					$lines = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
					$sub_iname_ctr++;
				}
				if($lines) {
					if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count} = 0;
					}
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count} + $lines;
				}
				
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase} ) {
					$words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
				}
				if($words) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count} + $words;
				}
				$words = 0;
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree} ) {
					$words = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
				}
				if($words) {
					if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count} = 0;
					}
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count} + $words;
				}
				
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase} ) {
					$chars = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{tbase}->{count};
				}
				if($chars) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}->{count} + $chars;
				}
				$chars = 0;
				if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{subtree} ) {
					$chars = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$code}->{chars}->{subtree}->{count};
				}
				if($chars) {
					if(!exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}->{count} = 0;
					}
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}->{count} + $chars;
				}

			}
#			$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_list}->{$code} = 1;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_list}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{inames} = $base_iname_ctr;
			if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_list}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_list}->{$code} + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{inames} = $sub_iname_ctr;
			}

			if($base_code) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_base_codes}->{$base_code} = 1;
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes}->{$code} = 1;
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{chars}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}->{count};
				}
				if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{chars}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}->{count};
				}
			
			} else {
				if(exists $base_codes{$code}) {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes}->{$code} = 0;
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} = 0;
				#	$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} = 1;
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{lines}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_codes}->{$code} + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{words}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{chars}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{chars}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_nested_code_stats}->{$code}->{chars}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{chars}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}->{count};
					}
				} else {
					$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} = 0;
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{tbase}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{lines}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_codes}->{$code} + $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{lines}->{subtree}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{tbase}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{words}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{words}->{subtree}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{chars}->{tbase}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{tbase}->{count};
					}
					if(exists $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}) {
						$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_prime_code_stats}->{$code}->{chars}->{subtree}->{count} = $data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$code}->{chars}->{subtree}->{count};
					}
				}
			}
#			if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$base_code}->{lines}->{tbase} ) {
#				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$base_code}->{lines}->{tbase}->{$iname} = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$base_code}->{lines}->{tbase}->{count};
#			}
#			if(exists $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$base_code}->{lines}->{subtree} ) {
#				$data_post_coding->{aquad_meta_coding}->{all_inames}->{x_code_stats}->{$base_code}->{lines}->{subtree}->{$iname} = $data_post_coding->{post_coding}->{$iname}->{x_code_stats}->{$base_code}->{lines}->{subtree}->{count};
#			}
		}
#		say "[$my_shortform_server_type][$me] all inames, final code ct[".scalar(keys %{ $final_codectrhref })."]";
	}

	if(scalar(keys %$aspectctrhref)) {
		##
		my $aspects_words = 0;
		my $aspects_ratings = 0;
		my $all_aspects_4_words = 0;
		my $all_aspects_4_count = 0;
		my $all_aspects_5_words = 0;
		my $all_aspects_5_count = 0;
		foreach my $aspect (keys %$aspectctrhref) {
			if(!$aspect) {
				next;
			}
			if($aspect=~/^\s+/) {
				next;
			}
			my $aspects_4_words = 0;
			my $aspects_4_count = 0;
			my $aspects_5_words = 0;
			my $aspects_5_count = 0;
			my ($lines,$words,$chars,$ratings) = (0,0,0,0);
			foreach my $iname (keys %{ $data_post_coding->{post_coding} }) {
				if(exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect} ) {
					if(defined $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{chars}->{total}->{count}) {
						$chars = $chars + $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{chars}->{total}->{count};
					}
					if(defined $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total}->{count}) {
						$words = $words + $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total}->{count};
						$data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total}->{integral_sum} = $words;
					}
					if(defined $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{lines}->{total}->{count}) {
						$lines = $lines + $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{lines}->{total}->{count};
					}
					if(defined $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total}->{count}) {
						$ratings = $ratings + $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_5}->{count}) {
						$aspects_5_count = $aspects_5_count + $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_5}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_5}->{integral_sum}) {
						$aspects_5_words = $aspects_5_words + $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_5}->{integral_sum};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_4}->{count}) {
						$aspects_4_count = $aspects_4_count + $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_4}->{count};
					}
					if(exists $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{ratings}->{total_4}->{integral_sum}) {
						$aspects_4_words = $aspects_4_words + $data_post_coding->{post_coding}->{$iname}->{aspect_stats}->{$aspect}->{words}->{total_4}->{integral_sum};
					}
				}
			}
			if($chars) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{chars}->{total}->{count} = $chars;
			}
			if($words) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{words}->{total}->{integral_sum} = $words;
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{words_4}->{total}->{integral_sum} = $aspects_4_words;
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{words_5}->{total}->{integral_sum} = $aspects_5_words;
				$aspects_words = $aspects_words + $words;
				$all_aspects_4_words = $all_aspects_4_words + $aspects_4_words;
				$all_aspects_5_words = $all_aspects_5_words + $aspects_5_words;
			}
			if($lines) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{lines}->{total}->{count} = $lines;
			}
			if($ratings) {
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{ratings}->{total}->{count} = $ratings;
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{ratings_4}->{total}->{count} = $aspects_4_count;
				$data_post_coding->{aquad_meta_coding}->{all_inames}->{per_aspect_stats}->{$aspect}->{ratings_5}->{total}->{count} = $aspects_5_count;
				$aspects_ratings = $aspects_ratings + $ratings;
				$all_aspects_4_count = $all_aspects_4_count + $aspects_4_count;
				$all_aspects_5_count = $all_aspects_5_count + $aspects_5_count;
			}
		}

		if($aspects_ratings) {
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings}->{total}->{count} = $aspects_ratings;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratios}->{words}->{per_unit_rating} = $aspects_words / $aspects_ratings;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_4}->{ratings}->{count} = $all_aspects_4_count;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratings}->{count} = $all_aspects_5_count;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_4}->{ratios}->{std_4}->{ratings4_to_total_ratings} = $all_aspects_4_count / $aspects_ratings;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_4}->{ratios}->{std_4}->{words4_per_unit_rating4} = $all_aspects_4_words / $all_aspects_4_count;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_4}->{ratios}->{hyper_4}->{words4_per_unit_to_all_words_per_unit} = ($all_aspects_4_words / $all_aspects_4_count) / ($aspects_words / $aspects_ratings);
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{words5_per_unit_to_all_words_per_unit} = ($all_aspects_5_words / $all_aspects_5_count) / ($aspects_words / $aspects_ratings);
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_to_total_ratings} = $all_aspects_5_count / $aspects_ratings;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{words5_per_unit_rating5} = $all_aspects_5_words / $all_aspects_5_count;
		}
		if($aspects_words) {
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{words}->{total}->{integral_sum} = $aspects_words;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratios}->{ratings}->{per_word} = $aspects_ratings / $aspects_words;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_4}->{words}->{integral_sum} = $all_aspects_4_words;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{words}->{integral_sum} = $all_aspects_5_words;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_4}->{ratios}->{std_4}->{words4_to_total_words} = $all_aspects_4_words / $aspects_words;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{words5_to_total_words} = $all_aspects_5_words / $aspects_words;
		}
		if($all_aspects_4_words) {
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_4}->{ratios}->{std_4}->{ratings4_per_word4} = $all_aspects_4_count / $all_aspects_4_words;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_4}->{ratios}->{hyper_4}->{ratings4_per_word_to_all_ratings_per_word} = ($all_aspects_4_count / $all_aspects_4_words) / ($aspects_ratings / $aspects_words);
		}
		if($all_aspects_5_words) {
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_word5} = $all_aspects_5_count / $all_aspects_5_words;
			$data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{ratings5_per_word_to_all_ratings_per_word} = ($all_aspects_5_count / $all_aspects_5_words) / ($aspects_ratings / $aspects_words);
		}
	}

#		say "[$my_shortform_server_type][$me] all inames, final code ct[".scalar(keys %{ $final_codectrhref })."]";

	## loop over inames to summarize any data across the iname cats
	my $all_words_to_ratings_ratio = $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratios}->{words}->{per_unit_rating};
	my $all_ratings_to_words_ratio = $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratios}->{ratings}->{per_word};
	my $all_ratings5_to_words5_ratio = $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_word5};
	my $all_words5_to_all_words_ratio = $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{words5_to_total_words};
	foreach my $iname (keys %{ $data_post_coding->{post_coding} }) {
		my $aspects_ratings = 0;
		my $aspects_words = 0;
		my $aspects_4_ratings = 0;
		my $aspects_4_words = 0;
		my $aspects_5_ratings = 0;
		my $aspects_5_words = 0;
		if(exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total}->{count}) {
			$aspects_ratings = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total}->{count};
		}
		if(exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total}->{integral_sum}) {
			$aspects_words = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total}->{integral_sum};
		}
		if(exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total_4}->{count}) {
			$aspects_4_ratings = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings}->{total_4}->{count};
		}
		if(exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total_4}->{integral_sum}) {
			$aspects_4_words = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{words}->{total_4}->{integral_sum};
		}
		if(exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratings}->{count}) {
			$aspects_5_ratings = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratings}->{count};
		}
		if(exists $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{words}->{integral_sum}) {
			$aspects_5_words = $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{words}->{integral_sum};
		}


		if($aspects_ratings) {
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_unit_iname_rating} = $aspects_words / $aspects_ratings;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_total_aspects_words} = $aspects_words / $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{words}->{total}->{integral_sum};
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{hyper}->{iname_words_per_unit_to_total_words_per_unit} = ($aspects_words / $aspects_ratings) / $all_words_to_ratings_ratio;
		}
		if($aspects_words) {
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_per_iname_word} = $aspects_ratings / $aspects_words;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_to_total_aspects_ratings} = $aspects_ratings / $data_post_coding->{aquad_meta_coding}->{all_inames}->{all_aspect_stats}->{ratings}->{total}->{count};
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{hyper}->{iname_ratings_per_word_to_total_ratings_per_word} = ($aspects_ratings / $aspects_words) / $all_ratings_to_words_ratio;
		}
		if($aspects_4_ratings) {
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratios}->{std_4}->{words4_per_unit_iname4_rating} = $aspects_4_words / $aspects_4_ratings;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratios}->{std_4}->{words4_per_total_iname_words} = $aspects_4_words / $aspects_words;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratios}->{hyper_4}->{words4_per_unit_to_iname_words_per_unit} = ($aspects_4_words / $aspects_4_ratings) / $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_unit_iname_rating};
		}
		if($aspects_4_words) {
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratios}->{std_4}->{ratings4_per_iname4_word} = $aspects_4_ratings / $aspects_4_words;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratios}->{std_4}->{ratings4_per_total_iname_ratings} = $aspects_4_ratings / $aspects_ratings;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_4}->{ratios}->{hyper_4}->{ratings4_per_word_to_iname_ratings_per_word} = ($aspects_4_ratings / $aspects_4_words) / $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_per_iname_word};
		}
		if($aspects_5_ratings) {
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{words5_per_unit_iname5_rating} = $aspects_5_words / $aspects_5_ratings;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_total_iname_ratings} = $aspects_5_ratings / $aspects_ratings;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{words5_per_unit_to_iname_words_per_unit} = ($aspects_5_words / $aspects_5_ratings) / $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{words_per_unit_iname_rating};
		}
		if($aspects_5_words) {
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{ratings5_per_iname5_word} = $aspects_5_ratings / $aspects_5_words;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{std_5}->{words5_per_total_iname_words} = $aspects_5_words / $aspects_words;
			$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{ratings5_per_word_to_iname_ratings_per_word} = ($aspects_5_ratings / $aspects_5_words) / $data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratios}->{std}->{ratings_per_iname_word};
			if($all_ratings5_to_words5_ratio) {
				$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{ratings5_per_word_to_all_ratings5_per_word} = ($aspects_5_ratings / $aspects_5_words) / $all_ratings5_to_words5_ratio;
			}
			if($all_words5_to_all_words_ratio) {
				$data_post_coding->{post_coding}->{$iname}->{all_aspect_stats}->{ratings_5}->{ratios}->{hyper_5}->{words5_per_iname_words_to_all_words5} = ($aspects_5_words / $aspects_words) / $all_words5_to_all_words_ratio;
			}
		}
	}
	
	return $taskid;
}
sub make_amc_file {
	####
	## .amc file format
	## fixed field sizes, 2x fields
	## - field 1 (80x, code name, text at beginning)
	## - field 2 (10x, frequency count, number at beginning)
	####
	my ($iname,$taskid,$trace,$trace_more) = @_;
#	my $parsed_sent_info = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info};
	my $codectrhref = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{code_counts};
#	my $filedata = {};
	my $filestr = '';

	## make padding
	my $padding = "";
	for (my $i=0; $i<80; $i++) {
		$padding = $padding . ' ';
	}
	say "[taskid:$taskid] iname[$iname] make code frequency amc file, codes[".scalar(keys %$codectrhref)."] length padding[".length($padding)."]" if $trace;

	foreach my $code (sort {$a cmp $b} keys %$codectrhref) {
		my $freq = $codectrhref->{$code};
		my $freq_form = &pad_suffix($freq);

		$code = $code . $padding;
		my $field = substr($code,0,80);
#		my $line = $field . $freq_form . "__x";
		my $line = $field . $freq_form;
#		$filedata->{$line} = 1;
		if(!$filestr) {
			$filestr = $line . "\n";
			next;
		}
		$filestr = $filestr . $line . "\n";
	}
	return $filestr;
}
sub make_sentence_aco_file {
	####
	## .aco file format
	## fixed field sizes [field size, field type], 5x fields
	## - field 1 (10x, start line num, number at end)
	## - field 2 (10x, end line num, number at end)
	## - field 3 (60x, code name, text at beginning)
	## - field 4 (10x, char count start location, number at beginning)
	## - field 5 (10x, chars in segment, number at beginning)
	##
	## !! no line merge in this method. each code lists every matching sentence
	##
	####
	my ($file_codes,$iname,$taskid,$trace,$trace_more) = @_;
	
	my $tcodes = undef;
	if(exists $data_coding->{$iname}->{re_codes}->{sentences}) {
		$tcodes = $data_coding->{$iname}->{re_codes}->{sentences};
	}
#	my $sent_info = undef;
#	if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info}) {
#		$sent_info = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info};
#	}

	if(!defined $tcodes or !scalar(keys %$tcodes)) {
		say "[make aco][$taskid] this iname[$iname] has no re_codes";
		return undef;
	}
	
	my $remap = 0;
	my $parsed_sent_info = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info};
	if(exists $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2}) {
		$parsed_sent_info = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info_2};
		$remap = 1;
	}
	my $filedata = {};
	
	## clear code stats...retain nothing
#	if(exists $data_post_coding->{post_coding}->{$iname}->{code_stats} and scalar(keys %{ $data_post_coding->{post_coding}->{$iname}->{code_stats} })) {
#		$data_post_coding->{post_coding}->{$iname}->{code_stats} = undef;
#	}
	
	my $detail_trace = 0;
	if($trace_more) {
		$detail_trace = 1;
	}
	## make padding
	my $padding = "";
	for (my $i=0; $i<60; $i++) {
		$padding = $padding . ' ';
	}
	say "[taskid:$taskid] iname[$iname] make sentence-based aco file, tcodes[".scalar(keys %$tcodes)."] length padding[".length($padding)."]" if $trace;
	my $start_total = 1;
	my $char_count = 1;
	my $description = "data code";
	
	my $sorter = {};
	my $cctr = 0;
	foreach my $sent (keys %$tcodes) {
		if($sent=~/^t(\d+)s(\d+)/i) {
			my $t = $1;
			my $s = $2;
			$sorter->{$t}->{$s} = $sent;
			$cctr++;
		}
	}
	say "[taskid:$taskid] iname[$iname] post sentence sorter, [$cctr] sentences";
	my $char_counter = 0;
	my $char_offset = 0;
	
	my $codectrhref = {};
#	if(exists $file_codes->{code_rack}) {
#		$codehref = $file_codes->{code_rack};
#	}
	
	my $start = 0;
	my $end = 0;
	my $line_ctr = 1;

	my $aco_profile_codes = undef;
	if(exists $data_coding->{$iname}->{profile}->{aco_codes}) {
		$aco_profile_codes = $data_coding->{$iname}->{profile}->{aco_codes};
	}
	if(defined $aco_profile_codes) {
		my $start_part = &pad_prefix('1');
		my $end_part = &pad_prefix('1');
		my $total_part = &pad_suffix('0');
		my $char_part = &pad_suffix('1');
		foreach my $code (keys %{$aco_profile_codes}) {
			$code = "/" . $code . ":" . $aco_profile_codes->{$code} . $padding;
			my $field = substr($code,0,60);
			my $line = $start_part . $end_part . $field . $total_part . $char_part . "__x";
			$filedata->{$start}->{$end}->{$line} = 1;
		}
		$start++;
		$end++;
	}

#	$sorter->{$t}->{$s} = $sent;

	foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
		## new topic...increment line count to skip topic title
		$line_ctr++;
#		$start++;
#		$end++;
		
		foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
			my $skey = $sorter->{$tindex}->{$sindex};

			if(!scalar(keys %{ $tcodes->{$skey}->{codes} }) and !$tcodes->{$skey}->{sentence}) {
				## delete stuff....and move on...
				delete $tcodes->{$skey}->{sentence};
				$tcodes->{$skey}->{codes} = undef;
				delete $tcodes->{$skey}->{codes};
				$tcodes->{$skey} = undef;
				delete $tcodes->{$skey};
				next;
			}
			
			my $tskey = $skey;
			if($remap) {
				if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{sentence_struct}->{$skey} or !$data_postparse->{parse_multi_struct}->{multi_txt}->{sentence_struct}->{$skey}) {
					say "[taskid:$taskid] iname[$iname] aco maker, NOT able to remap tskey[$skey] ... no value!";
					next;
				} else {
					if(!exists $data_postparse->{parse_multi_struct}->{multi_txt}->{sentence_struct}->{$skey}->{tskey_map}) {
						say "[taskid:$taskid] iname[$iname] aco maker, NOT able to remap tskey[$skey] ... no *tskey_map* key!";
						next;
					}
					if(!$data_postparse->{parse_multi_struct}->{multi_txt}->{sentence_struct}->{$skey}->{tskey_map}) {
						say "[taskid:$taskid] iname[$iname] aco maker, NOT able to remap tskey[$skey] ... no *tskey_map* key value!";
#						say "[taskid:$taskid] iname[$iname] aco maker, NOT able to remap tskey[$skey] ... no *tskey_map* key!";
						next;
					}
					$tskey = $data_postparse->{parse_multi_struct}->{multi_txt}->{sentence_struct}->{$skey}->{tskey_map};
				}
			}
			if(!$tskey) {
				say "\t\twhat the fuck!!! why is this null? skey[$skey] remap[$remap]";
				next;
			}

			$line_ctr++;
			my $start_char = 0;
			if(exists $parsed_sent_info->{$tskey}->{begin}->{chars} and $parsed_sent_info->{$tskey}->{begin}->{chars}) {
				$start_char = $parsed_sent_info->{$tskey}->{begin}->{chars};
			} else {
				## say error
				say "[taskid:$taskid] iname[$iname] aco maker, post_parse sent[$tskey] has no start chars[". $parsed_sent_info->{$tskey}->{begin} . "] begin ct[".scalar(keys %{ $parsed_sent_info->{$tskey}->{begin} })."]";
			}
			my $line_count = 0;
			if(exists $parsed_sent_info->{$tskey}->{counts}->{lines} and $parsed_sent_info->{$tskey}->{counts}->{lines}) {
				$line_count = $parsed_sent_info->{$tskey}->{counts}->{lines};
			} else {
				## say error
				say "[taskid:$taskid] iname[$iname] aco maker, post_parse lines is null at skey[$skey] [$tskey] has no counts[". $parsed_sent_info->{$tskey}->{counts} . "] cts[".scalar(keys %{ $parsed_sent_info->{$tskey}->{counts} })."]";
			}
#			my $line_count = $parsed_sent_info->{$tskey}->{counts}->{lines};
#			$char_count = length($tcodes->{$skey}->{sentence});
			$char_count = length($parsed_sent_info->{$tskey}->{sentence});
			if(!defined $parsed_sent_info->{$tskey}->{sentence} or !$char_count) {
				say "[taskid:$taskid] iname[$iname] aco maker, not able to locate sentence text for tskey[$tskey] skey[$skey]!";
#				next;
			}
			if($start_char < $char_counter) {
				if($start_char < 10) {
					$char_offset = $char_counter;
				}
			}
			$char_counter = $start_char + $char_offset;

#			my $start_form = &pad_prefix($start);
#			my $end_form = &pad_prefix($end);
			my $start_form = &pad_prefix($line_ctr);
			my $end_form = &pad_prefix($line_ctr);
			my $total_form1 = &pad_prefix($start_char);
			my $total_form = &pad_suffix($char_counter);
			my $char_form = '---------';
			if($char_count) {
				$char_form = &pad_suffix($char_count);
			}

			if(!scalar(keys %{ $tcodes->{$skey} })) {
				$tcodes->{$skey} = undef;
				delete $tcodes->{$skey};
				next;
			}
			if(exists $tcodes->{$skey}->{overall_char_begin}) {
				delete $tcodes->{$skey}->{overall_char_begin};
			}
			if(exists $tcodes->{$skey}->{begin_char_ct}) {
				delete $tcodes->{$skey}->{begin_char_ct};
			}
			if(!scalar(keys %{ $tcodes->{$skey}->{codes} }) and !$tcodes->{$skey}->{sentence}) {
				## delete stuff....and move on...
				delete $tcodes->{$skey}->{sentence};
				$tcodes->{$skey}->{codes} = undef;
				delete $tcodes->{$skey}->{codes};
				$tcodes->{$skey} = undef;
				delete $tcodes->{$skey};
				next;
			}
			if(!exists $tcodes->{$skey}->{sentence}) {
				$tcodes->{$skey}->{sentence} = $parsed_sent_info->{$tskey}->{sentence};
			}
			if(!$tcodes->{$skey}->{sentence}) {
				$tcodes->{$skey}->{sentence} = $parsed_sent_info->{$tskey}->{sentence};
			}
			my $postcode_words = 0;
			if(exists $parsed_sent_info->{$tskey}->{counts}->{words}) {
				$postcode_words = $parsed_sent_info->{$tskey}->{counts}->{words};
			}
			my $postcode_lines = 0;
			if(exists $parsed_sent_info->{$tskey}->{counts}->{lines}) {
				$postcode_lines = $parsed_sent_info->{$tskey}->{counts}->{lines};
			}
			my $postcode_chars = 0;
			if(exists $parsed_sent_info->{$tskey}->{counts}->{chars}) {
				$postcode_chars = $parsed_sent_info->{$tskey}->{counts}->{chars};
			}
			
			foreach my $cindex (keys %{$tcodes->{$skey}->{codes}}) {
				my $code = $tcodes->{$skey}->{codes}->{$cindex};
				if(!exists $codectrhref->{$code}) {
					$codectrhref->{$code} = 0;
				}
				$codectrhref->{$code}++;
#				my $line = $start_form . $end_form . $field . $total_form1 . $total_form . $char_form . "__x";

				if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{words}->{total}->{count} + $postcode_words; ##$parsed_sent_info->{$tskey}->{counts}->{words};
				if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{lines}->{total}->{count} + $postcode_lines; ##$parsed_sent_info->{$tskey}->{counts}->{lines};
				if(!exists $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count}) {
					$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} = 0;
				}
				$data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} = $data_post_coding->{post_coding}->{$iname}->{code_stats}->{$code}->{chars}->{total}->{count} + $postcode_chars; ##$parsed_sent_info->{$tskey}->{counts}->{chars};

				$code = $code . $padding;
				my $field = substr($code,0,60);
				my $line = $start_form . $end_form . $field . $total_form . $char_form . "__x";
#				say "  line[".$line."]" if $trace;
				$filedata->{$start}->{$end}->{$line} = 1;

			}
		}
	}
	$codes_dirty->{re_codes} = 1;
	$codes_dirty->{freq_codes} = 1;
	$codes_dirty->{post_coding} = 1;
	
	my $filestr = '';
	foreach my $skey (sort {$a <=> $b} keys %$filedata) {
		foreach my $ekey (sort {$a <=> $b} keys %{$filedata->{$skey}}) {
			foreach my $lkey (sort {$a eq $b} keys %{$filedata->{$skey}->{$ekey}}) {
				my ($line,$throw) = split '__',$lkey;
				$filestr = $filestr . $line . "\n";
			}
		}
	}
#	$data_postparse->{post_parse}->{$iname}->{atx_txt}->{code_counts} = $codectrhref;
	
	return $filestr;
}
sub pad_prefix {
	my ($num) = @_;
	
	my $len = length($num);
	
	for (my $i=$len; $i<10; $i++) {
		$num = ' ' . $num;
	}

	return $num;
}
sub pad_suffix {
	my ($num) = @_;
	
	my $len = length($num);
	
	for (my $i=$len; $i<10; $i++) {
		$num = $num . ' ';
	}

	return $num;
}


sub parse_text_files {

	my $ydata = {};
	my $file_count = 1;
	$lines_final = [];
	my @pfiles = ();
	my @sfiles = ();
	my @atxfiles = ();
	my $p_files = [];
	my $atx_files = [];
	if(!defined $data_coding) {
		$data_coding = {};
	}
	if(!defined $topic_to_code_mapping) {
		$topic_to_code_mapping = {};
	}
	
	while(scalar(@file_list)) {
		my $file = shift @file_list;
#		push @sfiles,$file;
		
		my $out_file = shift @outfile_list;
		
		my $idata = undef;

		if(open(my $fh, '<', $file)) {
			$idata = do { local $/; <$fh> };
		} else {
			print "ERROR! cannot open [$file]\n";
		}

		say "\nBegin parse of [$file]" if $runtime;
		
		my ($ydata) = &manage_parsing($file_count,$file,$out_file,$lines_final,$ydata,$idata,$special_words,$atx_files,$p_files,\@sfiles,$data_coding,$topic_to_code_mapping,$trace);

#		say "Lines of text in file{$file_count] - [".scalar(@$lines_aref)."]. subtotal lines [".scalar(@$lines_final)."]" if $runtime;
		
		$file_count++;
	}

	$file_count--;
	say "\nNumber of files parsed [$file_count]. Dumping to yaml" if $runtime;

	&dump_yaml_to_yml($ydata,$yml_dir,$yamlfile,$trace);
	
	my $final_str = &make_string($lines_final,$trace);
 
	my $afile = $cod_dir . "all_data-{s pS}.txt";
	open AFILE, ">$afile" or die $!;

	print AFILE $final_str;
	print "Wrote test file [$afile] for all data\n" if $trace;
	close AFILE;

	####
	## Create:
	##  dissertation.nam - names of parsed text-line files
	##  aqd7{mem.fil - names of source text files
	##  {S_Analysis} - names of text files in atx form (pure text with atx extended)
	##
	##  copy over starting text files to .atx
	####
	my $pfile = $cod_dir . $project_name . ".nam";
	my $filestr = '';
#	for (my $i=0; $i<scalar(@pfiles); $i++) {
	for (my $i=0; $i<scalar(@$p_files); $i++) {
		my $f = $p_files->[$i];
		$filestr = $filestr . $f . "\n";
	}
	open PFILE, ">$pfile" or die $!;
	print PFILE $filestr;
	close PFILE;

	my $sfile = $cod_dir . $src_files_filename;	
	my $filestr2 = '';
	for (my $i=0; $i<scalar(@sfiles); $i++) {
		$filestr2 = $filestr2 . $sfiles[$i] . "\n";
	}
	open SFILE, ">$sfile" or die $!;
	print SFILE $filestr2;
	close SFILE;
	
	my $atxfile = $cod_dir . $atx_files_filename;	
	my $filestr3 = '';
#	for (my $i=0; $i<scalar(@atxfiles); $i++) {
	for (my $i=0; $i<scalar(@$atx_files); $i++) {
		$filestr3 = $filestr3 . $atx_files->[$i] . ".atx\n";
	}
	open ATXFILE, ">$atxfile" or die $!;
	print ATXFILE $filestr3;
	close ATXFILE;

	
	if(!defined $data_coding) {
		die "CODE FAIL! fix your mess.";
	}
	&dump_coding_to_yml($data_coding,$yml_dir,$codingfile,$trace);

	my $a_yaml = &make_analytics_file($data_coding,$trace,0);
	if(!defined $a_yaml) {
		die "CODE FAIL! fix your mess.";
	}
	&dump_coding_to_yml($a_yaml,$yml_dir,$analyticsfile,$trace);
	
}

sub manage_parsing {
	my ($filenum,$infile,$outfile,$lines_all,$ydata,$filedata,$special_words,$atx_files,$p_files,$sfiles,$data_coding,$topic_to_code_mapping,$trace) = @_;

#	my $file_codes = undef;
	if($infile=~/-/) {
		&multi_parse_file($filenum,$infile,$lines_all,$ydata,$filedata,$special_words,$atx_files,$p_files,$sfiles,$data_coding,$topic_to_code_mapping,$trace);
	
	} else {
		my $lines_aref = [];

		($ydata,$lines_aref) = &parse_file($filenum,$lines_all,$ydata,$filedata,$special_words,$data_coding,$topic_to_code_mapping,$trace);
	
		say "Lines of text in file{$filenum] - [".scalar(@$lines_aref)."]. subtotal lines [".scalar(@$lines_final)."]" if $runtime;

		my $short_yaml = $ydata->{FILEDATA}->{$filenum};

		if($outfile) {
#			my $file_str = &make_better_string($short_yaml,$lines_aref,$trace);

			my $name = $lines_aref->[0];
			my ($interviewee,$stuff) = split '_',$name;
			$interviewee = uc $interviewee;
			#say "interviewee name_code (and data key) [$interviewee] name[$name] datacoding[$data_coding] [".$data_coding->{$interviewee}."]" if $trace;

			my $file_codes = $data_coding->{$interviewee}->{codes};
			$name = lc $name;
			my $f = "{s- cS}" . $name . ".atx";
			my $tf = $name . ".txt";
			my $atf = $name . ".atx";
			my $acof = $name . ".aco";

			push @$atx_files,$name;
			push @$p_files,$f;
			push @$sfiles,$tf;

			my @text_lines = ();

			$data_coding->{$interviewee}->{profile}->{files}->{s_cS} = $f;
			$data_coding->{$interviewee}->{profile}->{files}->{atx} = $atf;

			my $file_str = &make_sentences_string($file_codes,$name,$short_yaml,$lines_aref,$trace);
			$f = $cod_dir . $f;
			open TFILE, ">$f" or die $!;
			print TFILE $file_str;
			print "Wrote {s cS} text file [$f] for [".scalar(@$lines_aref)."] lines data\n" if $trace;
			close TFILE;

			my $file_text = &write_atx_file($file_codes,$short_yaml,\@text_lines,$trace);
			$atf = $cod_dir . $atf;
			open TXTFILE, ">$atf" or die $!;
			print TXTFILE $file_text;
			print "Wrote atx text file [$atf] for [".length($file_text)."] chars data\n" if $trace;
			close TXTFILE;

			my $file_txt = &rewrite_text_file($file_codes,$short_yaml,\@text_lines,$trace);
			$tf = $txt_dir . $tf;
			open TTXTFILE, ">$tf" or die $!;
			print TTXTFILE $file_txt;
			print "Wrote txt text file [$tf] for [".length($file_txt)."] chars data\n" if $trace;
			close TTXTFILE;
			$data_coding->{$interviewee}->{profile}->{files}->{txt} = $tf;

			my $dfile = $yml_dir . $yamlfile;
			my $yfile = $yml_dir . $name . ".yml";
			$yfile = lc $yfile;
			$data_coding->{$interviewee}->{profile}->{files}->{yml_results} = $yfile;
			$data_coding->{$interviewee}->{profile}->{files}->{yml_combined} = $dfile;

			my $str = &make_aco_file($file_codes,$trace);
			$acof = $txt_dir . $acof;
			open ACOFILE, ">$acof" or die $!;
			print ACOFILE $str;
			print "Wrote aco text file [$acof] for [".length($str)."] chars data\n" if $trace;
			close ACOFILE;
			$data_coding->{$interviewee}->{profile}->{files}->{aco} = $acof;

		}
	}
	say "Count of pfiles created [".scalar(@$p_files)."]." if $trace;

	return ($ydata);

}

sub parse_file {
	my ($filenum,$lines_all,$ydata,$filedata,$special_words,$data_coding,$topic_to_code_mapping,$trace) = @_;

	my $ignore_words = $special_words->{ignore_words};
	my $active_words = $special_words->{active_verbs};
	my $file_codes = undef;
	
	my $len = length($filedata);

	say "raw file[$filenum] length chars[$len]" if $trace;

	my ($prenewdata,$themes) = &extract_themes($filedata,$trace);
	say "data length - minus themes [".length($prenewdata)."]  filenum[$filenum]" if $trace;

	my ($newdata,$comments) = &extract_setting_comments($prenewdata,$trace);
	say "data length - comment markers [".length($newdata)."]  filenum[$filenum]" if $trace;


	my $new_data = &remove_extra_wspace($newdata,$trace);
	
	## make everything lowercase
	my $new_idata = lc $new_data;
	

	$len = length($new_data);
	say "trimmed filenum[$filenum] data length [$len]" if $trace;

	my ($topics,$blocks) = &extract_topics($new_data,$trace);

	my @keep_orig_topic = ();
	for (my $t=0; $t<scalar(@$topics); $t++) {
		$data_coding->{runlinks}->{topics}->{$topics->[$t]} = 1;
#		say "....topic [$t] [".$topics->[$t]."]";
		push @keep_orig_topic,$topics->[$t];
	}

	my $blocs = {};
	my $wordblocs = {};
	my $phraseblocs = {};
	my $counts_href = {};
	my $lines_aref = &scrub_topic_blocks($topics,$blocks,$blocs,$wordblocs,$phraseblocs,$trace);
	say "total aquad lines in file[$filenum] [".scalar(@$lines_aref)."]" if $trace;
	
	my $name = $lines_aref->[0];
	if(!defined $lines_aref->[0]) {
		die "horrible death....file name is missing! at [".__LINE__."]\n";
	}
	my ($interviewee,$stuff) = split '_',$name;
	$interviewee = uc $interviewee;
	say "interviewee name_code (and data key) [$interviewee] name[$name]" if $trace;
	
	if(!defined $data_coding or !exists $data_coding->{runlinks}->{name_codes}) {
		$data_coding->{runlinks}->{name_codes}->{$interviewee} = 0;
	}
	say "data coding[$data_coding] [".scalar(keys %{$data_coding->{runlinks}->{name_codes}})."]" if $trace;
	my $found = 0;
	my $nameactive = 0;
	foreach my $int (keys %{$data_coding->{runlinks}->{name_codes}}) {
		if($int=~/^$interviewee$/i) {
			$nameactive = $data_coding->{runlinks}->{name_codes}->{$int};
			if($nameactive) {
				$file_codes = $data_coding->{$int};
			}
			$found = 1;
			last;
		}
	}
	if(!$found or !$nameactive) {
		$data_coding->{runlinks}->{name_codes}->{$interviewee} = 1;
		$data_coding->{$interviewee}->{profile}->{name_code} = $interviewee;
		$data_coding->{$interviewee}->{profile}->{role} = 'ee';
		$data_coding->{$interviewee}->{profile}->{collection_format}->{audio_rec} = 'wav';
		$data_coding->{$interviewee}->{profile}->{collection_format}->{audio_rec_time} = '1:29';
		$data_coding->{$interviewee}->{profile}->{collection_format}->{group_size} = 1;
		$data_coding->{$interviewee}->{profile}->{collection_format}->{start_time} = '13:00';
		$file_codes = $data_coding->{$interviewee};
	}
	
	$data_coding->{$interviewee}->{profile}->{num_code} = $filenum;
	$data_coding->{$interviewee}->{profile}->{files}->{root_name} = lc $name;
	$data_coding->{$interviewee}->{profile}->{files}->{src} = lc $name . ".txt";
	$data_coding->{$interviewee}->{profile}->{src_date} = $stuff;

	## update data codes with latest info....if available!
	$topic_to_code_mapping = $run_config->{parse_coding}->{topic_to_code_map};
	say "  topic mapping hash[$topic_to_code_mapping]";
	for (my $t=0; $t<scalar(@keep_orig_topic); $t++) {
		my $freeze = 0;
#		say "  ....topic exists [$t] [".$keep_orig_topic[$t]."] code[".$topic_to_code_mapping->{main_codes}."]";
		
		my $top = uc $keep_orig_topic[$t];
		if($keep_orig_topic[$t]=~/\?/) {
#			$keep_orig_topic[$t]=~s/\?//;
		}
		if(exists $topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]}) {
			if(!$topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]} or $topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]}=~/^1$/) {
				next;
			}
			say "   ....topic MAIN code map exists [$t] [".$keep_orig_topic[$t]."] code[".$topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]}."]";
#			if(exists $data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}) {
			if(!exists $data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} or !$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen}) {
				say "     ....topic code map not frozen...update topic[$top] to code[".$topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]}."]";
				$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{main_code} = $topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]};
				## clear code qualifiers
				$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{code_qualifiers}->{1} = '';
				$freeze = 1;
			}
		}
		if(exists $topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]}) {
			if(!$topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]} or $topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]}=~/^1$/) {
				next;
			}
			say "   ....topic ALT code map exists [$t] [".$keep_orig_topic[$t]."] code[".$topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]}."]";
			if(!exists $data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} or !$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen}) {
				say "     ....topic code map not frozen...update topic[$top] to code[".$topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]}."]";
				$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{alt_codes}->{1} = $topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]};
				$freeze = 1;
			}
		}
		if(exists $topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]}) {
			if(!$topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]} or $topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]}=~/^1$/) {
				next;
			}
			say "   ....topic SUB Links code map exists [$t] [".$keep_orig_topic[$t]."] code[".$topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]}."]";
			if(!exists $data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} or !$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen}) {
				say "     ....topic sub code map not frozen...update topic[$top] to code[".$topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]}."]";
				$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{code_qualifiers}->{1} = $topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]};
				$freeze = 1;
			}
		}
		say "  topic[$top] freeze state [$freeze]" if $trace;
		if($freeze) {
			$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} = 0;
			if($set_frozen) {
				$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} = 1;
			}
		}
	}
  

	## trim spaces
	my $words = {};
	my $twowords = {};
	my $wordcounts = {};
	my $ignore_ct = &make_word_counts($words,$ignore_words,$twowords,$blocs,$wordblocs,$phraseblocs,$wordcounts,$trace);

	#$active_words
	my $active = {};
	my $iszes = {};
	&find_phrases($active_words,$active,$iszes,$phraseblocs,$trace);

	my $ifzes = {};
	&find_ifthen($ifzes,$phraseblocs,$trace);

	my $lines = &trim_lines($lines_aref,$counts_href,$interviewee,$trace);
	
	my $ll = &append_lines($lines_all,$lines,$trace);
	
#	my $name = $lines->[0];
	say "for [$name} the topic ct[".scalar(@$topics)."] block ct[".scalar(@$blocks)."] blocs[".scalar(keys %$blocs)."]";
	say " also, unique words [".scalar(keys %$words)."] ignoring words ct[$ignore_ct]" if $trace;

	$ydata->{FILEDATA}->{$filenum}->{file} = $name;
	my $short_stack = $ydata->{FILEDATA}->{$filenum};
	
	&load_yml_data($short_stack,$themes,$comments,$topics,$blocs,$words,$twowords,$iszes,$ifzes,$phraseblocs,$wordcounts,$trace);

	&summary_yml_data($ydata,$short_stack,$phraseblocs,$trace);

	&coded_yml_data($ydata,$ignore_words,$trace);
	
	return ($ydata,$lines);
}

sub multi_parse_file {
	my ($filenum,$infile,$lines_all,$ydata,$filedata,$special_words,$atx_files,$p_files,$sfiles,$data_coding,$topic_to_code_mapping,$trace) = @_;

	my $ignore_words = $special_words->{ignore_words};
	my $active_words = $special_words->{active_verbs};

	my $name_generator = {};
	
	my $len = length($filedata);

	say "raw file [$filenum] length chars[$len]" if $trace;
	
	my ($p1,$p2) = split '_',$infile;
	if($p1!~/-/) {
		die "bad file name [$infile]\n";
	}
	my @p = split '-',$p1;
	my $p2end = $p2;
	if($p2 =~ /(.*)\.txt/i) {
		$p2end = $1;
	}
	
	if(!defined $data_coding or !exists $data_coding->{runlinks}->{name_codes}) {
		$data_coding->{runlinks}->{name_codes} = {};
	}

	for (my $i=0; $i<scalar(@p); $i++) {
		my $f = $p[$i];
		$name_generator->{$f} = $p2;
		say "for file[$infile] make[$f] split-able in text";
		$filedata =~ s/\(($f)\)/+\\$1\\+/gi;

		my $found = 0;
		foreach my $int (keys %{$data_coding->{runlinks}->{name_codes}}) {
			if($int=~/^$f$/i) {
				$found = 1;
				last;
			}
		}
		if(!$found) {
			my $int = uc $f;
			$data_coding->{runlinks}->{name_codes}->{$int} = 1;
			$data_coding->{$int}->{profile}->{name_code} = $int;
			$data_coding->{$int}->{profile}->{role} = 'ee';
			$data_coding->{$int}->{profile}->{gender} = 'M';
			$data_coding->{$int}->{profile}->{age_category} = '4';
			$data_coding->{$int}->{profile}->{collection_format}->{audio_rec} = 'wav';
			$data_coding->{$int}->{profile}->{collection_format}->{audio_rec_time} = '1:29';
			$data_coding->{$int}->{profile}->{collection_format}->{group_size} = 4;
			$data_coding->{$int}->{profile}->{collection_format}->{start_time} = '13:00';
			$data_coding->{$int}->{codes}->{topic_coding} = {};
		}
		my $inter = uc $f;
		$data_coding->{$inter}->{profile}->{files}->{src} = $infile;
		$data_coding->{$inter}->{profile}->{src_date} = $p2end;
	}

	my ($prenewdata,$themes) = &extract_themes($filedata,$trace);
	say "data length - minus themes [".length($prenewdata)."]  filenum[$filenum]" if $trace;

	my ($newdata,$comments) = &extract_setting_comments($prenewdata,$trace);
	say "data length - comment markers [".length($newdata)."]  filenum[$filenum]" if $trace;

	my $new_data = &remove_extra_wspace($newdata,$trace);
	
	## make everything lowercase
	my $new_idata = lc $new_data;
#	print $new_data;
#	die "\n";
	
	$len = length($new_data);
	say "trimmed data length [$len]  filenum[$filenum]" if $trace;

	my ($topics,$blocks) = &extract_topics($new_data,$trace);

	my @keep_orig_topic = ();
	for (my $t=0; $t<scalar(@$topics); $t++) {
		$data_coding->{runlinks}->{topics}->{$topics->[$t]} = 1;
#		say "....topic [$t] [".$topics->[$t]."]";
		push @keep_orig_topic,$topics->[$t];
	}


	my $blocs = {};
	my $wordblocs = {};
	my $phraseblocs = {};
	my $lines_aref = &scrub_multi_topic_blocks(\@p,$topics,$blocks,$blocs,$wordblocs,$phraseblocs,$trace);
	say "total peeps[".scalar(keys %$lines_aref)."] in aquad filenum[$filenum]" if $trace;
#	say "topic ct [".scalar(@$topics)."]";
	
	## trim spaces
	my $words = {};
	my $twowords = {};
	my $wordcounts = {};
	my $ignore_ct = &make_multi_word_counts(\@p,$words,$ignore_words,$twowords,$blocs,$wordblocs,$phraseblocs,$wordcounts,$trace);
	say "words ignored in file[$filenum] [$ignore_ct] peep words[".scalar(keys %$words)."]" if $trace;
#	die "\n";

	#$active_words
	my $active = {};
	my $iszes = {};
	&find_multi_phrases($active_words,$active,$iszes,$phraseblocs,$trace);
	say "phrases in file[$filenum], iszes keys[".scalar(keys %$iszes)."] peep phrases[".scalar(keys %$phraseblocs)."]" if $trace;
#	die "\n";

	my $ifzes = {};
	&find_multi_ifthen($ifzes,$phraseblocs,$trace);
	say "if-thens in file[$filenum], ifzes keys[".scalar(keys %$iszes)."] peep phrases[".scalar(keys %$phraseblocs)."]" if $trace;
#	die "\n";

	&trim_multi_lines($lines_aref,$trace);
	say "trimmed lines in file[$filenum], lines_aref keys[".scalar(keys %$iszes)."] peep phrases[".scalar(keys %$phraseblocs)."]" if $trace;
#	die "\n";
	
	&append_multi_lines($lines_all,$lines_aref,$trace);
	say "appended new lines in file[$filenum], lines_aref keys[".scalar(keys %$lines_aref)."] new all_lines[".scalar(@$lines_all)."]" if $trace;
#	die "\n";

	my $fcount = 1;
	my $trace_more = 0;
	foreach my $peep (keys %$name_generator) {
		my $ext = $name_generator->{$peep};
		$ext =~ s/\.txt//i;
		my $name = lc $peep;
		$name = $name . "_" . $ext;
		my $filecode = $filenum . "_" . $fcount;
		
		my $interviewee = uc $peep;

		## update data codes with latest info....if available!
		$topic_to_code_mapping = $run_config->{parse_coding}->{topic_to_code_map};
		say "  topic mapping hash[$topic_to_code_mapping]";
		for (my $t=0; $t<scalar(@keep_orig_topic); $t++) {
			my $freeze = 0;
	#		say "  ....topic exists [$t] [".$keep_orig_topic[$t]."] code[".$topic_to_code_mapping->{main_codes}."]";
			
			my $top = uc $keep_orig_topic[$t];
			if($keep_orig_topic[$t]=~/\?/) {
	#			$keep_orig_topic[$t]=~s/\?//;
			}
			if(exists $topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]}) {
				if(!$topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]} or $topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]}=~/^1$/) {
					next;
				}
				say "   ....topic MAIN code map exists [$t] [".$keep_orig_topic[$t]."] code[".$topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]}."]";
				if(!exists $data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} or !$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen}) {
				#if(exists $data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}) {
					say "     ....topic code map not frozen...update topic[$top] to code[".$topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]}."]";
					$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{main_code} = $topic_to_code_mapping->{main_codes}->{$keep_orig_topic[$t]};
					## clear code qualifiers
					$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{code_qualifiers}->{1} = '';
					$freeze = 1;
				}
			}
			if(exists $topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]}) {
				if(!$topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]} or $topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]}=~/^1$/) {
					next;
				}
				say "   ....topic ALT code map exists [$t] [".$keep_orig_topic[$t]."] code[".$topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]}."]";
				if(!exists $data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} or !$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen}) {
					say "     ....topic code map not frozen...update topic[$top] to code[".$topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]}."]";
					$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{alt_codes}->{1} = $topic_to_code_mapping->{alt_codes}->{$keep_orig_topic[$t]};
					$freeze = 1;
				}
			}
			if(exists $topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]}) {
				if(!$topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]} or $topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]}=~/^1$/) {
					next;
				}
				say "   ....topic SUB Links code map exists [$t] [".$keep_orig_topic[$t]."] code[".$topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]}."]";
				if(!exists $data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} or !$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen}) {
					say "     ....topic sub code map not frozen...update topic[$top] to code[".$topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]}."]";
					$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{code_qualifiers}->{1} = $topic_to_code_mapping->{code_sub_links}->{$keep_orig_topic[$t]};
					$freeze = 1;
				}
			}
			if($freeze) {
				$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} = 0;
				if($set_frozen) {
					$data_coding->{$interviewee}->{codes}->{topic_coding}->{$top}->{frozen} = 1;
				}
			}
		}

		$data_coding->{$interviewee}->{profile}->{num_code} = $filecode;
		$data_coding->{$interviewee}->{profile}->{files}->{root_name} = lc $name;
		my $file_codes = $data_coding->{$interviewee}->{codes};
	
		my @text_lines = ();
		
		if(!defined $lines_aref->{$peep}->[0]) {
			die "horrible death....file name is missing! at [".__LINE__."]\n";
		}
		say "for [$name} the topic ct[".scalar(@$topics)."] block ct[".scalar(@$blocks)."] blocs[".scalar(keys %$blocs)."]";
		say " also, unique words [".scalar(keys %$words)."] ignoring words ct[$ignore_ct]" if $trace;

		$ydata->{FILEDATA}->{$filecode}->{file} = $name;
		my $short_stack = $ydata->{FILEDATA}->{$filecode};
	
		&load_multi_yml_data($peep,$short_stack,$themes,$comments,$topics,$blocs,$words,$twowords,$iszes,$ifzes,$phraseblocs,$wordcounts,$trace);

		&summary_multi_yml_data($peep,$ydata,$short_stack,$phraseblocs,$trace);

		&coded_yml_data($ydata,$ignore_words,$trace);
#		die "\n";

		#my $short_yaml = $ydata->{FILEDATA}->{$filenum};
		my $f = "{s- cS}" . $name . ".atx";
		my $tf = $name . ".txt";
		my $atf = $name . ".atx";
		my $acof = $name . ".aco";

		push @$atx_files,$name;

		push @$p_files,$f;

		push @$sfiles,$tf;

		$data_coding->{$interviewee}->{profile}->{files}->{s_cS} = $f;
		$data_coding->{$interviewee}->{profile}->{files}->{atx} = $atf;

		my $file_str = &make_multi_sentences_string($file_codes,$name,$short_stack,$lines_aref->{$peep},$trace);
#		my $file_str = &make_better_string($short_stack,$lines_aref->{$peep},$trace);
		$f = $cod_dir . $f;
		open TFILE, ">$f" or die $!;
		print TFILE $file_str;
		print "Wrote {s cS} text file [$f] for [".scalar(@{$lines_aref->{$peep}})."] lines data\n" if $trace;
		close TFILE;

		my $file_text = &write_atx_file($file_codes,$short_stack,\@text_lines,$trace);
#		my $file_text = &rejoin_text_file($file_codes,$short_stack,\@text_lines,$trace);
#		my $file_text = &rejoin_text_file($peep,$topics,$phraseblocs,$data_coding,$trace);
		$atf = $cod_dir . $atf;
		open TXTFILE, ">$atf" or die $!;
		print TXTFILE $file_text;
		print "Wrote atx text file [$atf] for [".length($file_text)."] chars data\n" if $trace;
		close TXTFILE;
		
		my $file_txt = &rewrite_text_file($file_codes,$short_stack,\@text_lines,$trace);
		$tf = $txt_dir . $tf;
		open TTXTFILE, ">$tf" or die $!;
		print TTXTFILE $file_txt;
		print "Wrote txt text file [$tf] for [".length($file_txt)."] chars data\n" if $trace;
		close TTXTFILE;
		$data_coding->{$interviewee}->{profile}->{files}->{txt} = $tf;

		my $dfile = $yml_dir . $yamlfile;
		my $yfile = $yml_dir . $name . ".yml";
		$yfile = lc $yfile;
		$data_coding->{$interviewee}->{profile}->{files}->{yml_results} = $yfile;
		$data_coding->{$interviewee}->{profile}->{files}->{yml_combined} = $dfile;

		if($peep=~/^g0/i) {
			$trace_more = 1;
		}
		my $str = &make_aco_file($file_codes,$trace,$trace_more);
		$acof = $txt_dir . $acof;
		open ACOFILE, ">$acof" or die $!;
		print ACOFILE $str;
		print "Wrote aco text file [$acof] for [".length($str)."] chars data\n" if $trace;
		close ACOFILE;
		$data_coding->{$interviewee}->{profile}->{files}->{aco} = $acof;

		$fcount++;
	}

	return 1;
}

sub remove_extra_wspace {
	my ($idata,$trace) = @_;

	####
	## damn awkward method for removing spaces :)
	####
	my $position = 0;
	my $precount = 0;
	my $count = 0;
	my $prere =    qr/
					(\s)
					(?(?{$precount++})|(*FAIL))
				/x;
	my $re =    qr/
					(\s)(?{$position=pos})
					(?(?{$count++})|(*FAIL))
				/x;
	my ( @found ) = $idata =~ m/$prere/g;
	say "{TRACE} Spaces found ", scalar @found, " instances of space [\\s]: count[$precount]" if $trace;

	my $tmp_pos = 0;
	my @dup_pos = ();
	while( $idata =~ m/$re/g ) {
		my $diff = $position - $tmp_pos;
		if($diff==1) {
			say "{TRACE}  Found double spaces at ", $position if $trace;
			push @dup_pos,$tmp_pos;
		}
		$tmp_pos = $position;
	}
	my $c = 0;
	for (my $i=scalar(@dup_pos)-1; $i>=0; $i--) {
		pos($idata) = $dup_pos[$i];
		say "{TRACE}  Replacing space at ", $dup_pos[$i] if $trace;
		$idata =~ s/\G\s//g;
		if($c > 4) {
			last;
		}
		$c++;
	}
	$count = 0;
	my ( @found2 ) = $idata =~ m/$re/g;
	say "{TRACE} Space recheck; found ", scalar @found2, " instances of space [\\s]: count[$count]" if $trace;

	####
	## end of space removal
	####
	return $idata;
}

sub extract_themes {
	my ($filedata,$trace) = @_;

	my $detail_trace = 0;
	my $total_chars = length($filedata);
	my @parts = split('{',$filedata);
	say "file braces parts [".scalar(@parts)."] for total chars[$total_chars]" if $trace;

	my @themes = ();
	my @rejoin = ();
	my $parts_chars = 0;
	
	if(!scalar(@parts)) {
		return ($filedata,\@themes);
	}
	$rejoin[0] = $parts[0];
	$parts_chars = length($parts[0]);
	my $theme_chars = 0;
	for (my $i=1; $i<scalar(@parts); $i++) {
		my ($start,$end) = split('}',$parts[$i]);
		say "  split; part [$i] len[".length($parts[$i])."] start[".length($start)."] end[".length($end)."]" if $detail_trace;
		$parts_chars = $parts_chars + length($parts[$i]);
		$theme_chars = $theme_chars + length($start);
		push @rejoin,$end;
		push @themes,$start;
		say "  theme [$start]" if $trace;
	}
	say "filedata rejoin parts [".scalar(@rejoin)."]" if $detail_trace;
	my $check = $total_chars - ($parts_chars + scalar(@parts) - 1);
	if($check != 0) {
		say "lost some characters in theme parting! check[$check] total[$total_chars] parts[$parts_chars] themes[".scalar(@parts)."]";
		die "\tdying to fix\n";
	}
	
	my $newstr = '';
	if(scalar(@rejoin)) {
		$newstr = $rejoin[0];
	}
	my $rejoin_chars = length($rejoin[0]);
	for (my $i=1; $i<scalar(@rejoin); $i++) {
		say "  rejoin; already[".length($newstr)."] new[".length($rejoin[$i])."]" if $detail_trace;
		$newstr = $newstr . $rejoin[$i];
		$rejoin_chars = $rejoin_chars + length($rejoin[$i]);
	}
	my $check2 = $parts_chars - ($theme_chars + $rejoin_chars + scalar(@rejoin) - 1);
	if($check2 != 0) {
		say "lost some characters in theme extraction! check[$check2] parts[$parts_chars] themes[$theme_chars] rejoin[$rejoin_chars]";
		say "...check theme braces for additional closing brace\n";
		die "\tdying to fix\n";
	}
	return ($newstr,\@themes);
}
sub extract_setting_comments {
	my ($filedata,$trace) = @_;

	my $detail_trace = 0;
	my $total_chars = length($filedata);
	my @parts = split /\(\(/,$filedata;
	say "file comment parts [".scalar(@parts)."] for total chars[$total_chars]" if $trace;

	my %comments = ();
	my @rejoin = ();
	my $parts_chars = 0;
	
	if(!scalar(@parts)) {
		return ($filedata,\%comments);
	}
	$rejoin[0] = $parts[0];
	$parts_chars = length($parts[0]);
	my $theme_chars = 0;
	my $chopped_chars = 0;
	my $hashtag_chars = 0;
	my $butt_parts_chars = 0;
	my $start_part_chars = length($parts[0]);;
	for (my $i=1; $i<scalar(@parts); $i++) {
		my ($start,$end) = split /\)\)\.*/,$parts[$i];
		say "  comment split; part [$i] len[".length($parts[$i])."] start[".length($start)."] end[".length($end)."]" if $detail_trace;
		$parts_chars = $parts_chars + length($parts[$i]);
		$theme_chars = $theme_chars + length($start);
		$butt_parts_chars = $butt_parts_chars + length($end);
		$chopped_chars = $chopped_chars + length($parts[$i]) - length($end) - length($start);
		my $ht = "##COM" . $i . "##";
		$hashtag_chars = $hashtag_chars + length($ht);
		my $c = $ht . $end;
		push @rejoin,$c;
		$comments{$i} = $start;
		say "  comment [$start]" if $trace;
	}
	say "filedata rejoin parts [".scalar(@rejoin)."]" if $detail_trace;
	my $dcheck = $start_part_chars + $butt_parts_chars + $theme_chars + ((scalar(@parts) - 1) * 2) + $chopped_chars;
	my $check = $total_chars - $dcheck;
	if($check != 0) {
		say "lost some characters in comment parting! check[$check] dcheck[$dcheck] chopped[$chopped_chars] total[$total_chars] parts[$parts_chars] startpart[$start_part_chars] butts[$butt_parts_chars] comments[$theme_chars] hashs[".$hashtag_chars."]";
		die "\tdying to fix";
	}
	
	my $newstr = '';
	if(scalar(@rejoin)) {
		$newstr = $rejoin[0];
	}
	my $rejoin_chars = length($rejoin[0]);
	for (my $i=1; $i<scalar(@rejoin); $i++) {
		say "  comment rejoin; already[".length($newstr)."] new[".length($rejoin[$i])."]" if $detail_trace;
		$newstr = $newstr . $rejoin[$i];
		$rejoin_chars = $rejoin_chars + length($rejoin[$i]);
	}
	my $dcheck2 = $start_part_chars + $butt_parts_chars + $hashtag_chars;
	my $check2 = $rejoin_chars - $dcheck2;
	if($check2 != 0) {
		say "lost some characters in comment extraction! check[$check2] dcheck[$dcheck2] start[$start_part_chars] butts[$butt_parts_chars] hashtags[$hashtag_chars] rejoin[$rejoin_chars]";
		say "...check comments for additional closing ))";
		die "\tdying to fix";
	}
	return ($newstr,\%comments);
}

sub extract_topics {
	my ($filedata,$trace) = @_;

	my $detail_trace = 0;
	my @parts2 = split('<',$filedata);
	say "file topic divisions [".scalar(@parts2)."]" if $trace;

	my @topics = ();
	my @blocks = ();
	for (my $i=0; $i<scalar(@parts2); $i++) {
		my ($start,$end) = split('>',$parts2[$i]);
		if($i==0) {
			if(!defined $start) {
				next;
			}
			say "topic [$start]" if $trace;
			if(length($start) > 0) {
				$blocks[0] = $start;
			}
		}
		if($i>0) {
			push @blocks,$end;
			push @topics,$start;
		}		
		say "topic [$start]" if $detail_trace;
	}

	say "topic ct[".scalar(@topics)."] block ct[".scalar(@blocks)."]" if $trace;
	
	return (\@topics,\@blocks);
}
sub extract_topics_to_yml {
	my ($filedata,$ydata,$trace) = @_;

	my $detail_trace = 1;
	my @parts2 = split('<',$filedata);
	say "file topic divisions [".scalar(@parts2)."]" if $trace;

	my @topics = ();
	my @blocks = ();
	my $index = 0;
	my $filenameset = 0;
	for (my $i=0; $i<scalar(@parts2); $i++) {
		my ($start,$end) = split('>',$parts2[$i]);
		if($i==0) {
			if(!defined $start) {
				say "first line split blank topic[] block[]" if $trace;
				if($end) {
					print "\nWARNING! File structure is suspect at first line!!\n\n";
					die "[".$parts2[$i]."] file structure is broke...\n";
				}
				next;
			}
			if(!$end or $end=~/^\s+$/) {
				say "topic [$start] must be name" if $trace;
				if(length($start) > 0) {
					my $key = "t".$index;
					$ydata->{$key}->{topic} = '_NAME_';
					$ydata->{$key}->{block} = $start;
					$index++;
				}
				$filenameset = 1;
				next;
			}
		}
		if(!$filenameset) {
			if(!$end or $end=~/^\s+$/) {
				say "topic [$start] must be name" if $trace;
				if(length($start) > 0) {
					my $key = "t".$index;
					$ydata->{$key}->{topic} = '_NAME_';
					$ydata->{$key}->{block} = $start;
					$index++;
				}
				$filenameset = 1;
				next;
			}
		}
		push @blocks,$end;
		push @topics,$start;
		my $key = "t".$index;
		$ydata->{$key}->{topic} = $start;
		if(!$end or $end=~/^\s+$/) {
			say "topic is blank...setting to [_BLANK_]" if $trace;
			$end = '_BLANK_';
		}
		$ydata->{$key}->{block} = $end;
		$index++;
		say "topic [$start]" if $detail_trace;
	}

	say "topic ct[".scalar(@topics)."] block ct[".scalar(@blocks)."] ydata size[".scalar(keys %$ydata)."]" if $trace;
	
	return (\@topics,\@blocks);
}

sub scrub_topic_blocks {
	my ($topics,$tblocks,$blocs,$wordblocs,$phraseblocs,$trace) = @_;

	my $detail_trace = 0;
	my @lines = ();
	my $shift_out_filename = 1;
	for (my $i=0; $i<scalar(@$topics); $i++) {
		my $j = $i + 1;
		if($i == 0) {
			my @bparts = split /[!\.\?]/,$tblocks->[$i];
			say "file name[".$topics->[$i]."] has bloc val[".$bparts[0]."]";
			push @lines,$topics->[$i];
			if(!defined $bparts[0] or !$bparts[0]) {
				next;
			}
			if($bparts[0]=~/^\s+$/) {
				next;
			}
			$shift_out_filename = 0;
		}
		## fix the hashkey index setting
		$j = $j - $shift_out_filename;
		## make topic uppercase for callout and comparisons
		$topics->[$i] = uc $topics->[$i];

		say "  topic, index[$i] ct[$j] topic text[".$topics->[$i]."] " if $detail_trace;
		my @bparts = split /[!\.\?]/,$tblocks->[$i];
		my $ctr = 0;
		push @lines,$topics->[$i];
		for (my $ii=0; $ii<scalar(@bparts); $ii++) {
			if(!$bparts[$ii]) {
				next;
			}
			if($bparts[$ii]=~/^\s+$/) {
				next;
			}
			$ctr++;
			my $k = $ctr;
			
			$blocs->{$j}->{$k} = $bparts[$ii];

			my $string3 = $bparts[$ii];

			## make everything lowercase for comparisons
			my $strdata = lc $bparts[$ii];

			my $count1 = 0;
			my $count2 = 0;
			my $count3 = 0;
			my $count4 = 0;
			my $re1 =    qr/
							([\[\]\"])
							(?(?{$count1++})|(*FAIL))
						/x;
			my $re2 =    qr/
							([\[\]\"\(\)\?\,\;\:])
							(?(?{$count2++})|(*FAIL))
						/x;
			my $re3 =    qr/
							([\[\]\"])
							(?(?{$count3++})|(*FAIL))
						/x;
						
			## substitution of second word for first (not fully viable...) first|second
#			my $re4 =    qr/
#							([\|])
#							(?(?{$count4++})|(*FAIL))
#						/x;

			## set lowercase, retain punctuation
			my $string1 = $strdata;
			$string1 =~ s/$re1//g;
			my $newstr = $string1;
			$newstr =~ s/##COM\d+##\s//gi;
			push @lines,$newstr;

			## retain CAPS and punctuation
			$string3 =~ s/$re3//g;
			$phraseblocs->{$j}->{$k} = $string3;
						
			## set lowercase, clear all non-alpha chars
			my $string2 = $strdata;
			$string2 =~ s/$re2//g;
			$wordblocs->{$j}->{$k} = $string2;

		}
	}
	## if the filename is at the top of the topic array...shift it off both topics and bloc arrays
	if($shift_out_filename) {
		say "  removing filename[".$topics->[0]."] from topic array" if $trace;
		shift @$topics;
		shift @$tblocks;
	}
	
	say "Scrubbed topic ct[".scalar(@$topics)."] yielding; wordblock ct[".scalar(keys %{$wordblocs})."] phrasebloc ct[".scalar(keys %{$phraseblocs})."] lines[".scalar(@lines)."]" if $trace;
	return \@lines;
}
sub scrub_multi_topic_blocks {
	my ($peeps,$topics,$tblocks,$blocs,$wordblocs,$phraseblocs,$trace) = @_;

	my $detail_trace = 0;
	my @lines = ();
	my $peeplines = {};
	my $shift_out_filename = 1;
	say "multi scrubbing for peeps, ct[".scalar(@$peeps)."} topic ct[".scalar(@$topics)."] block ct[".scalar(@$tblocks)."] href blocs[".scalar(keys %$blocs)."]";
	for (my $i=0; $i<scalar(@$topics); $i++) {
		my $j = $i + 1;
		if($i == 0) {
			my @bparts = split /[!\.\?]/,$tblocks->[$i];
			say "file name[".$topics->[$i]."] has bloc val[".$bparts[0]."]";
			for (my $x=0; $x<scalar(@$peeps); $x++) {
				$peeplines->{$peeps->[$x]} = [];
				my $g = $peeplines->{$peeps->[$x]};
				push @$g,$topics->[$i];
			}
			if(!defined $bparts[0] or !$bparts[0]) {
				next;
			}
			if($bparts[0]=~/^\s+$/) {
				next;
			}
			$shift_out_filename = 0;
		}
		$j = $j - $shift_out_filename;
#		push @lines,$topics->[$i];
		$topics->[$i] = uc $topics->[$i];
		my @pparts = split /\+\\/,$tblocks->[$i];
		my $pctr = {};
		say "  topic, index[$i] ct[$j] topic text[".$topics->[$i]."] peepparts[".scalar(@pparts)."]" if $detail_trace;
		for (my $jj=0; $jj<scalar(@$peeps); $jj++) {
			my $reg = $peeps->[$jj];
			if(!exists $pctr->{$reg}) {
				$pctr->{$reg} = 0;
			}
			my $plines = $peeplines->{$peeps->[$jj]};
			push @$plines,$topics->[$i];
			for (my $ii=0; $ii<scalar(@pparts); $ii++) {
				if($pparts[$ii]=~/^$reg/i) {
					say "    matched peep[".$reg."] peepblock size[".length($pparts[$ii])."]" if $detail_trace;
					my ($lead,$meat) = split /\\\+/,$pparts[$ii];
					my @bparts = split /[!\.\?]/,$meat;
					my $sctr = 0;
					say "      for peep [".$reg."] peepmatch[$lead] sparts[".scalar(@bparts)."] sentence ct so far[".$pctr->{$reg}."]" if $detail_trace;
					for (my $iii=0; $iii<scalar(@bparts); $iii++) {
						if(!$bparts[$iii]) {
							next;
						}
						if($bparts[$iii]=~/^\s+$/) {
							next;
						}
						$pctr->{$reg} = $pctr->{$reg} + 1;
						my $k = $pctr->{$reg};
						$blocs->{$j}->{$reg}->{$k} = $bparts[$iii];

						my $string3 = $bparts[$iii];

						## make everything lowercase for comparisons
						my $strdata = lc $bparts[$iii];
					
						my $count1 = 0;
						my $count2 = 0;
						my $count3 = 0;
						my $re1 =    qr/
										([\[\]\"])
										(?(?{$count1++})|(*FAIL))
									/x;
						my $re2 =    qr/
										([\[\]\"\(\)\?\,\;\:])
										(?(?{$count2++})|(*FAIL))
									/x;
						my $re3 =    qr/
									([\[\]\"])
									(?(?{$count3++})|(*FAIL))
								/x;

						## set lowercase, retain punctuation
						my $string1 = $strdata;
						$string1 =~ s/$re1//g;
						my $newstr = $string1;
						$newstr =~ s/##COM\d+##\s//gi;
#						$newstr =~ s/##COM\d+##//g;
						push @$plines,$newstr;
	
						## retain CAPS and punctuation
						$string3 =~ s/$re3//g;
						$phraseblocs->{$j}->{$reg}->{$k} = $string3;

						## set lowercase, clear all non-alpha chars
						my $string2 = $strdata;
						$string2 =~ s/$re2//g;
						$wordblocs->{$j}->{$reg}->{$k} = $string2;
						$sctr++;
					}
					say "      for peep[$reg] topicct[$j] sentence blocs size[$sctr][".scalar(keys %{$blocs->{$j}->{$reg}})."] phraseblocks size[".scalar(keys %{$phraseblocs->{$j}->{$reg}})."] peep lines[".scalar(@$plines)."]" if $detail_trace;
				}
			}
		}
	}
	
	## if the filename is at the top of the topic array...shift it off both topics and bloc arrays
	if($shift_out_filename) {
		say "  removing filename[".$topics->[0]."] from topic array" if $trace;
		shift @$topics;
		shift @$tblocks;
	}

	say "Scrubbed topic ct[".scalar(@$topics)."] yielding; wordblock ct[".scalar(keys %{$wordblocs})."] phrasebloc ct[".scalar(keys %{$phraseblocs})."] lines[".scalar(keys %$peeplines)."]" if $trace;
	return $peeplines;

}

sub make_word_counts {
	my ($words,$ignore_words,$twowords,$blocs,$wordblocs,$phraseblocs,$wordcounts,$trace) = @_;

	my $detail_trace = 0;
	my $ignore_ct = 0;
	say "narrative blocs ct[".scalar(keys %{$phraseblocs})."]" if $trace;
	foreach my $key (sort { $a <=> $b } keys %$blocs) {
		say " line data bloc [$key] ct[".scalar(keys %{$blocs->{$key}})."]" if $detail_trace;
		foreach my $k (keys %{$blocs->{$key}}) {
			my @lparts = split ' ',$blocs->{$key}->{$k};
			my $str = '';
			my @l = ();
			for (my $ii=0; $ii<scalar(@lparts); $ii++) {
				push @l,$lparts[$ii];
			}
			$str = $l[0];
			for (my $ii=1; $ii<scalar(@l); $ii++) {
				$str = $str . " " . $l[$ii];
			}
			$blocs->{$key}->{$k} = $str;
		}
	}
	foreach my $key (sort { $a <=> $b } keys %$phraseblocs) {
		say " phrasebloc [$key] ct[".scalar(keys %{$phraseblocs->{$key}})."]" if $detail_trace;
		foreach my $k (keys %{$phraseblocs->{$key}}) {
			my @lparts = split(' ',$phraseblocs->{$key}->{$k});
			my $str = '';
			my @l = ();
			for (my $ii=0; $ii<scalar(@lparts); $ii++) {
				push @l,$lparts[$ii];
			}
			$str = $l[0];
			for (my $ii=1; $ii<scalar(@l); $ii++) {
				$str = $str . " " . $l[$ii];
			}
			$phraseblocs->{$key}->{$k} = $str;
		}
	}
	foreach my $key (sort { $a <=> $b } keys %$wordblocs) {
		say " wordbloc [$key] ct[".scalar(keys %{$wordblocs->{$key}})."]" if $detail_trace;
		my $wordtally = {};
		foreach my $k (keys %{$wordblocs->{$key}}) {
			my @lparts = split(' ',$wordblocs->{$key}->{$k});
			my $str = '';
			my @l = ();
			for (my $ii=0; $ii<scalar(@lparts); $ii++) {
				if(exists $ignore_words->{$lparts[$ii]}) {
					## ignore this word
					$ignore_ct++;
					next;
				}
				push @l,$lparts[$ii];
				if(!exists $wordcounts->{$key}->{count}) {
					$wordcounts->{$key}->{count} = 0;
				}
				$wordcounts->{$key}->{count} = $wordcounts->{$key}->{count} + 1;
				if(!exists $wordtally->{$lparts[$ii]}) {
					$wordtally->{$lparts[$ii]} = 0;
					if(!exists $wordcounts->{$key}->{unique_count}) {
						$wordcounts->{$key}->{unique_count} = 0;
					}
					$wordcounts->{$key}->{unique_count} = $wordcounts->{$key}->{unique_count} + 1;
				}
				if(!exists $words->{$lparts[$ii]}) {
					$words->{$lparts[$ii]} = 0;
				}
				$words->{$lparts[$ii]} = $words->{$lparts[$ii]} + 1;
			
				if($ii>0) {
					if(exists $ignore_words->{$lparts[$ii-1]}) {
						## ignore previous word
						$ignore_ct++;
						next;
					}
					my $two = $lparts[$ii-1] . " " . $lparts[$ii];
#					if(!exists $twowords->{$two}) {
#						$twowords->{$two} = 0;
#					}
#					$twowords->{$two} = $twowords->{$two} + 1;
				}
			}
			$str = $l[0];
			for (my $ii=1; $ii<scalar(@l); $ii++) {
				$str = $str . " " . $l[$ii];
			}
			$wordblocs->{$key}->{$k} = $str;
		}
		$wordtally = undef;
	}
	return $ignore_ct;
}
sub make_multi_word_counts {
	my ($peeps,$words,$ignore_words,$twowords,$blocs,$wordblocs,$phraseblocs,$wordcounts,$trace) = @_;

	my $detail_trace = 0;
	my $ignore_ct = 0;
	say "word counts, narrative blocs ct[".scalar(keys %{$phraseblocs})."]" if $trace;
	
	#### 
	## trim both blocs and phraseblocs for extra spaces
	####
	foreach my $key (sort { $a <=> $b } keys %$blocs) {
		say " line data bloc [$key] ct[".scalar(keys %{$blocs->{$key}})."]" if $detail_trace;
		foreach my $peep (keys %{$blocs->{$key}}) {
			foreach my $k (keys %{$blocs->{$key}->{$peep}}) {
				my @lparts = split ' ',$blocs->{$key}->{$peep}->{$k};
				my $str = '';
				my @l = ();
				for (my $ii=0; $ii<scalar(@lparts); $ii++) {
					push @l,$lparts[$ii];
				}
				$str = $l[0];
				for (my $ii=1; $ii<scalar(@l); $ii++) {
					$str = $str . " " . $l[$ii];
				}
				$blocs->{$key}->{$peep}->{$k} = $str;
			}
		}
	}
#			for (my $jj=0; $jj<scalar(@$peeps); $jj++) {
	foreach my $key (sort { $a <=> $b } keys %$phraseblocs) {
		say " phrasebloc [$key] ct[".scalar(keys %{$phraseblocs->{$key}})."]" if $detail_trace;
		foreach my $peep (keys %{$phraseblocs->{$key}}) {
			foreach my $k (keys %{$blocs->{$key}->{$peep}}) {
				my @lparts = split(' ',$phraseblocs->{$key}->{$peep}->{$k});
				my $str = '';
				my @l = ();
				for (my $ii=0; $ii<scalar(@lparts); $ii++) {
					push @l,$lparts[$ii];
				}
				$str = $l[0];
				for (my $ii=1; $ii<scalar(@l); $ii++) {
					$str = $str . " " . $l[$ii];
				}
				$phraseblocs->{$key}->{$peep}->{$k} = $str;
			}
		}
	}
	foreach my $key (sort { $a <=> $b } keys %$wordblocs) {
		say " wordbloc [$key] ct[".scalar(keys %{$wordblocs->{$key}})."]" if $detail_trace;
		foreach my $peep (keys %{$wordblocs->{$key}}) {
			my $wordtally = {};
			foreach my $k (keys %{$blocs->{$key}->{$peep}}) {
				my @lparts = split(' ',$wordblocs->{$key}->{$peep}->{$k});
				my $str = '';
				my @l = ();
				for (my $ii=0; $ii<scalar(@lparts); $ii++) {
					if(exists $ignore_words->{$lparts[$ii]}) {
						## ignore this word
						$ignore_ct++;
						next;
					}
					push @l,$lparts[$ii];
					if(!exists $wordcounts->{$key}->{$peep}->{count}) {
						$wordcounts->{$key}->{$peep}->{count} = 0;
					}
					$wordcounts->{$key}->{$peep}->{count} = $wordcounts->{$key}->{$peep}->{count} + 1;
					if(!exists $wordtally->{$lparts[$ii]}) {
						$wordtally->{$lparts[$ii]} = 0;
						if(!exists $wordcounts->{$key}->{$peep}->{unique_count}) {
							$wordcounts->{$key}->{$peep}->{unique_count} = 0;
						}
						$wordcounts->{$key}->{$peep}->{unique_count} = $wordcounts->{$key}->{$peep}->{unique_count} + 1;
					}
					if(!exists $words->{$peep}->{$lparts[$ii]}) {
						$words->{$peep}->{$lparts[$ii]} = 0;
#						if(!exists $wordcounts->{$key}->{$peep}->{unique_count}) {
#							$wordcounts->{$key}->{$peep}->{unique_count} = 0;
#						}
#						$wordcounts->{$key}->{$peep}->{unique_count} = $wordcounts->{$key}->{$peep}->{unique_count} + 1;
					}
					$words->{$peep}->{$lparts[$ii]} = $words->{$peep}->{$lparts[$ii]} + 1;
			
					if($ii>0) {
						if(exists $ignore_words->{$lparts[$ii-1]}) {
							## ignore previous word
							$ignore_ct++;
							next;
						}
						my $two = $lparts[$ii-1] . " " . $lparts[$ii];
#						if(!exists $twowords->{$peep}->{$two}) {
#							$twowords->{$peep}->{$two} = 0;
#						}
#						$twowords->{$peep}->{$two} = $twowords->{$peep}->{$two} + 1;
					}
				}
				$str = $l[0];
				for (my $ii=1; $ii<scalar(@l); $ii++) {
					$str = $str . " " . $l[$ii];
				}
				$wordblocs->{$key}->{$peep}->{$k} = $str;
			}
			$wordtally = undef;
		}
	}
	return $ignore_ct;
}

sub find_phrases {
	my ($active_words,$active,$iszes,$phraseblocs,$trace) = @_;

	my $detail_trace = 0;
	my $wct = 1;
	foreach my $act (keys %$active_words) {
		#my $verb = $active_words->{$act};
		print "action word [".$act."] phraseblocks[".scalar(keys %$phraseblocs)."]\n" if $trace;
		foreach my $key (sort { $a <=> $b } keys %$phraseblocs) {
			foreach my $k (keys %{$phraseblocs->{$key}}) {
				if(!defined $phraseblocs->{$key}->{$k}) {
					next;
				}
				my @lparts = split ' ',$phraseblocs->{$key}->{$k};
#				print " bloc [$key] key[$k] word parts in bloc[".scalar(@lparts)."]\n" if $trace;
				for (my $ii=0; $ii<scalar(@lparts); $ii++) {
					if($lparts[$ii]!~/^$act$/i) {
						next;
					}
					my $str = $act;
					if($ii>0) {
						my $ctr = 5;
						for (my $jj=$ii-1; $jj >=0; $jj--) {
							$ctr--;
							if($lparts[$jj]=~/[\?\,\;\:\-]$/) {
								## end of previous phrase
								last;
							}
							if($lparts[$jj]=~/and|or/) {
								## end of previous phrase
								last;
							}
							$str = $lparts[$jj] . " " . $str;
							if(!$ctr) { last; }
						}
					}
					if($ii<scalar(@lparts)) {
						my $ctup = 5;
						for (my $jj=$ii+1; $jj<scalar(@lparts); $jj++) {
							$ctup--;
							if($lparts[$jj]=~/[\?\,\;\:\-]$/) {
								## end of previous phrase
								my $string = $lparts[$jj];
								$string =~ s/[\s\,\;\:\-]$//g;
								$str = $str . " " . $string;
								last;
							}
							if($lparts[$jj]=~/and|or/) {
								## end of previous phrase
								last;
							}
							$str = $str . " " . $lparts[$jj];
							if(!$ctup) { last; }
						}
					}
					if(!exists $iszes->{$act}->{$str}) {
						$iszes->{$act}->{$str} = 0;
#						print " bloc [$key] key[$k] actpos[$ii] phrase[$str] NEW PHRASE ct[".$iszes->{$act}->{$str}."]\n" if $trace;
					}
					$iszes->{$act}->{$str} = $iszes->{$act}->{$str} + 1;
					say " topic bloc[$key] sentence[$k] phrase word ct[".scalar(@lparts)."] actpos[$ii] phrase[$str] ct[".$iszes->{$act}->{$str}."]\n" if $detail_trace;
				}
			}
		}
	}
	return;
}
sub find_multi_phrases {
	my ($active_words,$active,$iszes,$phraseblocs,$trace) = @_;

	my $detail_trace = 0;
	my $wct = 1;
	foreach my $act (keys %$active_words) {
		#my $verb = $active_words->{$act};
		print "action word [".$act."] phraseblocks[".scalar(keys %$phraseblocs)."]\n" if $trace;
		foreach my $key (sort { $a <=> $b } keys %$phraseblocs) {
			foreach my $peep (keys %{$phraseblocs->{$key}}) {
				foreach my $k (keys %{$phraseblocs->{$key}->{$peep}}) {
					if(!defined $phraseblocs->{$key}->{$peep}->{$k}) {
						next;
					}
					my @lparts = split ' ',$phraseblocs->{$key}->{$peep}->{$k};
#				print " bloc [$key] key[$k] word parts in bloc[".scalar(@lparts)."]\n" if $trace;
					for (my $ii=0; $ii<scalar(@lparts); $ii++) {
						if($lparts[$ii]!~/^$act$/i) {
							next;
						}
						my $str = $act;
						if($ii>0) {
							my $ctr = 5;
							for (my $jj=$ii-1; $jj >=0; $jj--) {
								$ctr--;
								if($lparts[$jj]=~/[\?\,\;\:\-]$/) {
									## end of previous phrase
									last;
								}
								if($lparts[$jj]=~/and|or/) {
									## end of previous phrase
									last;
								}
								$str = $lparts[$jj] . " " . $str;
								if(!$ctr) { last; }
							}
						}
						if($ii<scalar(@lparts)) {
							my $ctup = 5;
							for (my $jj=$ii+1; $jj<scalar(@lparts); $jj++) {
								$ctup--;
								if($lparts[$jj]=~/[\?\,\;\:\-]$/) {
									## end of previous phrase
									my $string = $lparts[$jj];
									$string =~ s/[\s\,\;\:\-]$//g;
									$str = $str . " " . $string;
									last;
								}
								if($lparts[$jj]=~/and|or/) {
									## end of previous phrase
									last;
								}
								$str = $str . " " . $lparts[$jj];
								if(!$ctup) { last; }
							}
						}
						if(!exists $iszes->{$peep}->{$act}->{$str}) {
							$iszes->{$peep}->{$act}->{$str} = 0;
#						print " bloc [$key] key[$k] actpos[$ii] phrase[$str] NEW PHRASE ct[".$iszes->{$act}->{$str}."]\n" if $trace;
						}
						$iszes->{$peep}->{$act}->{$str} = $iszes->{$peep}->{$act}->{$str} + 1;
						say " topic bloc[$key] peep[$peep] sentence[$k] phrase word ct[".scalar(@lparts)."] actpos[$ii] phrase[$str] ct[".$iszes->{$act}->{$str}."]\n" if $detail_trace;
					}
				}
			}
		}
	}
	return;
}

sub find_ifthen {
	my ($ifzes,$phraseblocs,$trace) = @_;

	my $detail_trace = 0;
	my $wct = 1;
	my $start = 'if';
	my $trans = 'then';
	my $trans_alt = 'than';
	my $cont = 'so';
	my $if_limit = 20;
	my $then_limit = 20;
	my $so_limit = 16;
	
	foreach my $key (sort { $a <=> $b } keys %$phraseblocs) {
		## loop sentences in phrase blocs
		foreach my $k (keys %{$phraseblocs->{$key}}) {
			if(!defined $phraseblocs->{$key}->{$k}) {
				## if blank, skip
				next;
			}
			my @lparts = split ' ',$phraseblocs->{$key}->{$k};
			my $if_started = 0;
			my $str = '';
			my $ctr = 0;
			my $ct_good = 0;
			for (my $ii=0; $ii<scalar(@lparts); $ii++) {
				if($lparts[$ii]=~/^$start$/i) {
					$if_started = 1;
					$str = $start;
					next;
				}
				if($if_started and $ctr < $if_limit) {
					$str = $str . " " . $lparts[$ii];
					$ctr++;
					if($ctr > 3) {
						$ct_good = 1;
					}
					if($lparts[$ii]=~/^$trans|$trans_alt$/i) {
						if($ctr > $if_limit - $then_limit) {
							$if_limit = $then_limit;
							$ctr = 0;
						}
					}
					if($lparts[$ii]=~/^$cont$/i) {
						if($ctr > $if_limit - $so_limit) {
							$if_limit = $so_limit;
							$ctr = 0;
						}
					}
				}
			}
			if(length($str) and $ct_good) {
				my $skey = $key . "__" . $k;
#				if(!exists $ifzes->{ifthen}->{$str}) {
#					$ifzes->{ifthen}->{$str} = 0;
#						print " bloc [$key] key[$k] actpos[$ii] phrase[$str] NEW PHRASE ct[".$iszes->{$act}->{$str}."]\n" if $trace;
#				}
				$ifzes->{ifthen}->{$str} = $skey;
			}
		}
	}
	return 1;
}
sub find_multi_ifthen {
	my ($ifzes,$phraseblocs,$trace) = @_;

	my $detail_trace = 0;
	my $wct = 1;
	my $start = 'if';
	my $trans = 'then';
	my $trans_alt = 'than';
	my $cont = 'so';
	my $if_limit = 20;
	my $then_limit = 20;
	my $so_limit = 16;
	
	foreach my $key (sort { $a <=> $b } keys %$phraseblocs) {
		## loop sentences in phrase blocs
		foreach my $peep (keys %{$phraseblocs->{$key}}) {
			foreach my $k (keys %{$phraseblocs->{$key}->{$peep}}) {
				if(!defined $phraseblocs->{$key}->{$peep}->{$k}) {
					## if blank, skip
					next;
				}
				my @lparts = split ' ',$phraseblocs->{$key}->{$peep}->{$k};
				my $if_started = 0;
				my $str = '';
				my $ctr = 0;
				my $ct_good = 0;
				for (my $ii=0; $ii<scalar(@lparts); $ii++) {
					if($lparts[$ii]=~/^$start$/i) {
						$if_started = 1;
						$str = $start;
						next;
					}
					if($if_started and $ctr < $if_limit) {
						$str = $str . " " . $lparts[$ii];
						$ctr++;
						if($ctr > 3) {
							$ct_good = 1;
						}
						if($lparts[$ii]=~/^$trans|$trans_alt$/i) {
							if($ctr > $if_limit - $then_limit) {
								$if_limit = $then_limit;
								$ctr = 0;
							}
						}
						if($lparts[$ii]=~/^$cont$/i) {
							if($ctr > $if_limit - $so_limit) {
								$if_limit = $so_limit;
								$ctr = 0;
							}
						}
					}
				}
				if(length($str) and $ct_good) {
					my $skey = "t" . $key . "__s" . $k;
					$ifzes->{$peep}->{ifthen}->{$str} = $skey;
				}
			}
		}
	}
	return 1;
}

sub trim_line {
	my ($line,$counts_href,$trace) = @_;

	my @lparts = split ' ',$line;
	my @l = ();
	for (my $ii=0; $ii<scalar(@lparts); $ii++) {
		if($lparts[$ii]) {
			push @l,$lparts[$ii];
		}
	}
	$counts_href->{words} = scalar(@l);
	my $str = $l[0];
	for (my $ii=1; $ii<scalar(@l); $ii++) {
		$str = $str . " " . $l[$ii];
	}
	$counts_href->{chars} = length($str);
	return $str;
}
sub trim_lines {
	my ($lines,$counts_href,$iname,$trace) = @_;

	my @lines2 = ();
	my $ctr = 1;
	for (my $i=0; $i<scalar(@$lines); $i++) {
		my @lparts = split ' ',$lines->[$i];
		my $str = '';
		$counts_href->{$iname}->{words}->{$ctr} = scalar(@$lines);
		my @l = ();
		for (my $ii=0; $ii<scalar(@lparts); $ii++) {
			push @l,$lparts[$ii];
		}
		$str = $l[0];
		for (my $ii=1; $ii<scalar(@l); $ii++) {
			$str = $str . " " . $l[$ii];
		}
		$counts_href->{$iname}->{chars}->{$ctr} = length($str);
		push @lines2,$str;
		$ctr++;
	}
	return \@lines2;
}
sub trim_multi_lines {
	my ($lines,$trace) = @_;

	my @lines2 = ();
	my $plines2 = {};
	foreach my $peep (keys %$lines) {
		my $plines = $lines->{$peep};
		for (my $i=0; $i<scalar(@$plines); $i++) {
			if(!defined $plines->[$i]) {
				## if blank, skip
				next;
			}
			my @lparts = split ' ',$plines->[$i];
			my $str = '';
			my @l = ();
			for (my $ii=0; $ii<scalar(@lparts); $ii++) {
				push @l,$lparts[$ii];
			}
			$str = $l[0];
			for (my $ii=1; $ii<scalar(@l); $ii++) {
				$str = $str . " " . $l[$ii];
			}
			$plines->[$i] = $str;
		}
	}
	return 1;
}

sub append_lines {
	my ($lines_old,$lines_new,$trace) = @_;
	my $line_ct = scalar(@$lines_old);
	for (my $i=0; $i<scalar(@$lines_new); $i++) {
		push @$lines_old,$lines_new->[$i];
	}
	return $lines_old;
}
sub append_multi_lines {
	my ($lines_old,$lines_new,$trace) = @_;
	my $line_ct = scalar(@$lines_old);
	foreach my $peep (keys %$lines_new) {
		my $plines = $lines_new->{$peep};
		for (my $i=0; $i<scalar(@$plines); $i++) {
			push @$lines_old,$plines->[$i];
		}
	}
	return $lines_old;
}

sub load_yml_data {
	my ($_ydata,$themes,$comments,$topics,$blocs,$words,$twowords,$iszes,$ifzes,$phraseblocs,$wordcounts,$trace) = @_;

	my $detail_trace = 0;
	say "setting yaml, themes ct[".scalar(@$themes)."]" if $trace;
	for (my $i=0; $i<scalar(@$themes); $i++) {
		my $j = $i + 1;
		$_ydata->{themes}->{$j} = $themes->[$i];
	}
	say "storing comments in yaml, comment ct[".scalar(keys %$comments)."]" if $trace;
	foreach my $cindex (keys %$comments) {
		$_ydata->{comments}->{$cindex} = $comments->{$cindex};
	}
	
	say "setting yaml, topic ct[".scalar(@$topics)."]" if $trace;
	for (my $i=0; $i<scalar(@$topics); $i++) {
		my $j = $i + 1;
		$_ydata->{topics}->{$j}->{topic} = $topics->[$i];
		if(!exists $blocs->{$j}) {
			print "\tmissing bloc index [$j]\n";
			next;
		}
		my $s = $blocs->{$j};
		foreach my $k (sort { $a <=> $b } keys %$s) {
			## add comments back in
			my $pre = $phraseblocs->{$j}->{$k};
			my $prepre = $blocs->{$j}->{$k};
			foreach my $cindex (keys %$comments) {
				my $regmatch = "##COM" . $cindex . "##";
				if($pre=~/(.*)($regmatch)(.*)/i) {
					$pre = $1 . "((" . $comments->{$cindex} . "))" . $3;
				}
				if($prepre=~/(.*)($regmatch)(.*)/i) {
					$prepre = $1 . "((" . $comments->{$cindex} . "))" . $3;
				}
			}
#			$_ydata->{topics}->{$j}->{sentences}->{$m} = $pre;
			$_ydata->{topics}->{$j}->{sentences}->{$k} = $pre;
			$_ydata->{topics}->{$j}->{rawtext}->{$k} = $prepre;
			
		}
		$_ydata->{topics}->{$j}->{unique_words} = $wordcounts->{$j}->{unique_count};
		$_ydata->{topics}->{$j}->{total_words} = $wordcounts->{$j}->{count};
		print "  setting yaml, topic[".$topics->[$i]."] ct[".scalar(keys %$s)."]\n" if $detail_trace;
	}
	
	my $ctr = 1;
	foreach my $w (sort { $words->{$b} <=> $words->{$a} } keys %$words) {
		my $k = "w" . $ctr;
		if($ctr < 10) {
			$k = "w000" . $ctr;
		} elsif($ctr < 100) {
			$k = "w00" . $ctr;
		} elsif($ctr < 1000) {
			$k = "w0" . $ctr;
		}
		$_ydata->{wordcounts}->{words}->{$k}->{word} = $w;
		$_ydata->{wordcounts}->{words}->{$k}->{count} = $words->{$w};
		$ctr++;
	}
	say "setting yaml, words ct[".$ctr."]" if $trace;
	
	$ctr = 1;
	foreach my $w (sort { $twowords->{$b} <=> $twowords->{$a} } keys %$twowords) {
		my $k = "w" . $ctr;
		if($ctr < 10) {
			$k = "w000" . $ctr;
		} elsif($ctr < 100) {
			$k = "w00" . $ctr;
		} elsif($ctr < 1000) {
			$k = "w0" . $ctr;
		}
#		$_ydata->{wordcounts}->{twowords}->{$k}->{word} = $w;
#		$_ydata->{wordcounts}->{twowords}->{$k}->{count} = $twowords->{$w};
		$ctr++;
	}
	say "setting yaml, twowords ct[".$ctr."]" if $trace;
	
	foreach my $act (keys %$iszes) {
		my $acts = $iszes->{$act};
		$ctr = 1;
		foreach my $w (sort { $acts->{$b} <=> $acts->{$a} } keys %$acts) {
			my $k = "p" . $ctr;
			if($ctr < 10) {
				$k = "p000" . $ctr;
			} elsif($ctr < 100) {
				$k = "p00" . $ctr;
			} elsif($ctr < 1000) {
				$k = "p0" . $ctr;
			}
			$_ydata->{wordcentered}->{$act}->{$k}->{phrase} = $w;
			$_ydata->{wordcentered}->{$act}->{$k}->{count} = $acts->{$w};
			$ctr++;
		}
	}
	
	foreach my $act (keys %$ifzes) {
		my $ifs = $ifzes->{$act};
		$ctr = 1;
		my $prefix = "if";
		foreach my $w (sort { $ifs->{$b} eq $ifs->{$a} } keys %$ifs) {
			my $k = $prefix . $ctr;
			if($ctr < 10) {
				$k = $prefix . "000" . $ctr;
			} elsif($ctr < 100) {
				$k = $prefix . "00" . $ctr;
			} elsif($ctr < 1000) {
				$k = $prefix . "0" . $ctr;
			}
			my $skey = $ifs->{$w};
			my $sent = undef;
			if($skey=~/(\d+)__(\d+)/i) {
				my $blockkey = $1;
				my $sentencekey = $2;
				$sent = $phraseblocs->{$blockkey}->{$sentencekey};
			}
			if(!$sent) {
				die "bad key structure in phrase/sentence hash, skey[$skey]\n";
			}
			$_ydata->{causeeffect}->{$act}->{$k}->{phrase} = $w;
			$_ydata->{causeeffect}->{$act}->{$k}->{index} = $ctr;
			$_ydata->{causeeffect}->{$act}->{$k}->{sentence} = $sent;
			$_ydata->{causeeffect}->{$act}->{$k}->{sentencekeys} = $ifs->{$w};
			$ctr++;
		}
	}

	return;
}
sub load_multi_yml_data {
	my ($peep,$_ydata,$themes,$comments,$topics,$blocs,$words,$twowords,$iszes,$ifzes,$phraseblocs,$wordcounts,$trace) = @_;

	my $detail_trace = 0;
	say "setting yaml, themes ct[".scalar(@$themes)."]" if $trace;
	for (my $i=0; $i<scalar(@$themes); $i++) {
		my $j = $i + 1;
		$_ydata->{themes}->{$j} = $themes->[$i];
	}
	say "storing comments in yaml, comment ct[".scalar(keys %$comments)."]" if $trace;
	foreach my $cindex (keys %$comments) {
		$_ydata->{comments}->{$cindex} = $comments->{$cindex};
	}
	
	say "setting yaml, topic ct[".scalar(@$topics)."]" if $trace;
	for (my $i=0; $i<scalar(@$topics); $i++) {
		my $j = $i + 1;
		$_ydata->{topics}->{$j}->{topic} = $topics->[$i];
		if(!exists $blocs->{$j}) {
			print "\tmissing bloc index [$j]\n";
			next;
		}
		my $s = $blocs->{$j};
		foreach my $blocpeep (keys %{$blocs->{$j}}) {
			if($blocpeep=~/^$peep$/i) {
				foreach my $k (sort { $a <=> $b } keys %{$blocs->{$j}->{$blocpeep}}) {

					if(!$phraseblocs->{$j}->{$blocpeep}->{$k}) {
						$_ydata->{topics}->{$j}->{sentences}->{$k} = $phraseblocs->{$j}->{$blocpeep}->{$k};
						$_ydata->{topics}->{$j}->{rawtext}->{$k} = $blocs->{$j}->{$blocpeep}->{$k};
						next;
					}
					## add comments back in
					my $pre = $phraseblocs->{$j}->{$blocpeep}->{$k};
					my $prepre = $blocs->{$j}->{$blocpeep}->{$k};
					foreach my $cindex (keys %$comments) {
						my $regmatch = "##COM" . $cindex . "##";
						if($pre=~/(.*)($regmatch)(.*)/i) {
							$pre = $1 . "((" . $comments->{$cindex} . "))" . $3;
						}
						if($prepre=~/(.*)($regmatch)(.*)/i) {
							$prepre = $1 . "((" . $comments->{$cindex} . "))" . $3;
						}
					}
					$_ydata->{topics}->{$j}->{sentences}->{$k} = $pre;
					$_ydata->{topics}->{$j}->{rawtext}->{$k} = $prepre;
				}
				$_ydata->{topics}->{$j}->{unique_words} = $wordcounts->{$j}->{$peep}->{unique_count};
				$_ydata->{topics}->{$j}->{total_words} = $wordcounts->{$j}->{$peep}->{count};
			}
		}
		print "  setting yaml, topic[".$topics->[$i]."] ct[".scalar(keys %$s)."]\n" if $detail_trace;
	}

	my $ctr = 1;
	if(exists $words->{$peep}) {
		foreach my $w (sort { $words->{$peep}->{$b} <=> $words->{$peep}->{$a} } keys %{$words->{$peep}}) {
			my $k = "w" . $ctr;
			if($ctr < 10) {
				$k = "w000" . $ctr;
			} elsif($ctr < 100) {
				$k = "w00" . $ctr;
			} elsif($ctr < 1000) {
				$k = "w0" . $ctr;
			}
			$_ydata->{wordcounts}->{words}->{$k}->{word} = $w;
			$_ydata->{wordcounts}->{words}->{$k}->{count} = $words->{$peep}->{$w};
			$ctr++;
		}
	}
	say "  setting yaml words, words ct[".$ctr."]" if $trace;

	my $pctr = 0;
	if(exists $iszes->{$peep}) {
		foreach my $act (keys %{$iszes->{$peep}}) {
			my $acts = $iszes->{$peep}->{$act};
			$ctr = 1;
			foreach my $w (sort { $acts->{$b} <=> $acts->{$a} } keys %$acts) {
				my $k = "p" . $ctr;
				if($ctr < 10) {
					$k = "p000" . $ctr;
				} elsif($ctr < 100) {
					$k = "p00" . $ctr;
				} elsif($ctr < 1000) {
					$k = "p0" . $ctr;
				}
				$_ydata->{wordcentered}->{$act}->{$k}->{phrase} = $w;
				$_ydata->{wordcentered}->{$act}->{$k}->{count} = $acts->{$w};
				$ctr++;
				$pctr++;
			}
		}
	}
	say "  setting yaml phrases, action ct[".scalar(keys %{$_ydata->{wordcentered}})."] phrases set[$ctr]" if $trace;

	$pctr = 0;
	if(exists $ifzes->{$peep}) {
		foreach my $act (keys %{$ifzes->{$peep}}) {
			my $ifs = $ifzes->{$peep}->{$act};
			$ctr = 1;
			my $prefix = "if";
			foreach my $w (sort { $ifs->{$b} eq $ifs->{$a} } keys %$ifs) {
				my $k = $prefix . $ctr;
				if($ctr < 10) {
					$k = $prefix . "000" . $ctr;
				} elsif($ctr < 100) {
					$k = $prefix . "00" . $ctr;
				} elsif($ctr < 1000) {
					$k = $prefix . "0" . $ctr;
				}
				my $skey = $ifs->{$w};
				my $sent = undef;
				if($skey=~/t(\d+)__s(\d+)/i) {
					my $blockkey = $1;
					my $sentencekey = $2;
					$sent = $phraseblocs->{$blockkey}->{$peep}->{$sentencekey};
				}
				if(!$sent) {
					die "bad key structure in phrase/sentence hash, skey[$skey] peep[$peep] at line[".__LINE__."]\n";
				}
				$_ydata->{causeeffect}->{$act}->{$k}->{phrase} = $w;
				$_ydata->{causeeffect}->{$act}->{$k}->{index} = $ctr;
				$_ydata->{causeeffect}->{$act}->{$k}->{sentence} = $sent;
				$_ydata->{causeeffect}->{$act}->{$k}->{sentencekeys} = $ifs->{$w};
				$ctr++;
				$pctr++;
				say "    setting causeeffect, peep[$peep] key[$k] sentencekey[".$ifs->{$w}."] ct[".scalar(keys %$ifs)."]" if $detail_trace;
			}
		}
	}
	say "  setting yaml if-thenz, causes ct[".scalar(keys %{$_ydata->{causeeffect}})."] phrases set[$ctr]" if $trace;

	return;
}
	
sub summary_yml_data {
	my ($all_ydata,$_ydata,$phraseblocs,$trace) = @_;

	my $detail_trace = 0;
	my $filter_yaml = {};
	my $act_href = {};
	my $word_filter_yaml = {};
	my $word_href = {};
	
	say "Making summary data" if $trace;
	if(exists $all_ydata->{SUMMARYDATA}) {
		if(exists $all_ydata->{SUMMARYDATA}->{wordcentered}) {
			say "  old summary data; act ct[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}})."] word cts[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcounts}})."]" if $trace;
			foreach my $actkey (keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}}) {
				$act_href->{$actkey} = 1;
				foreach my $wkey (sort { $a cmp $b } keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}->{$actkey}}) {
					my $kkey = $all_ydata->{SUMMARYDATA}->{wordcentered}->{$actkey}->{$wkey}->{phrase};
					if(!exists $filter_yaml->{$actkey}->{$kkey}) {
						$filter_yaml->{$actkey}->{$kkey} = 0;
						say "   summary old; act[$actkey] wkey[$wkey] phrase[$kkey] NEW PHRASE ct[".$filter_yaml->{$actkey}->{$kkey}."]" if $detail_trace;
					}
					$filter_yaml->{$actkey}->{$kkey} = $filter_yaml->{$actkey}->{$kkey} + 1;
#					print "summary; act[$actkey] wkey[$wkey] phrase[$kkey] phrase ct[".$filter_yaml->{$kkey}."]\n" if $trace;
				}
			}
		}
		if(exists $all_ydata->{SUMMARYDATA}->{wordcounts}) {
			say "  old summary data; word cts[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcounts}})."]" if $trace;
			foreach my $wordkey (keys %{$all_ydata->{SUMMARYDATA}->{wordcounts}}) {
				$word_href->{$wordkey} = 1;
				foreach my $wkey (sort { $a cmp $b } keys %{$all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}}) {
					my $word = $all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}->{$wkey}->{word};
					$word_filter_yaml->{$wordkey}->{$word} = $all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}->{$wkey}->{count};
				
				}
			}
		}
	}
	say "  new summary data; act ct[".scalar(keys %{$_ydata->{wordcentered}})."]" if $trace;
	foreach my $actkey (keys %{$_ydata->{wordcentered}}) {
		$act_href->{$actkey} = 1;
		foreach my $wkey (sort { $a cmp $b } keys %{$_ydata->{wordcentered}->{$actkey}}) {
			my $kkey = $_ydata->{wordcentered}->{$actkey}->{$wkey}->{phrase};
			if(!exists $filter_yaml->{$actkey}->{$kkey}) {
				$filter_yaml->{$actkey}->{$kkey} = 0;
				say "   summary new; act[$actkey] wkey[$wkey] phrase[$kkey] NEW PHRASE ct[".$filter_yaml->{$actkey}->{$kkey}."]" if $detail_trace;
			}
			$filter_yaml->{$actkey}->{$kkey} = $filter_yaml->{$actkey}->{$kkey} + 1;
#			$filter_yaml->{$kkey} = 0;
		}
	}
	foreach my $wordkey (keys %{$_ydata->{wordcounts}}) {
		$word_href->{$wordkey} = 1;
		foreach my $wkey (sort { $a cmp $b } keys %{$_ydata->{wordcounts}->{$wordkey}}) {
			my $word = $_ydata->{wordcounts}->{$wordkey}->{$wkey}->{word};
			if(!exists $word_filter_yaml->{$wordkey}->{$word}) {
				$word_filter_yaml->{$wordkey}->{$word} = 0;
			}
			$word_filter_yaml->{$wordkey}->{$word} = $word_filter_yaml->{$wordkey}->{$word} + $_ydata->{wordcounts}->{$wordkey}->{$wkey}->{count};
		}
	}

	my $pctr = 0;
	foreach my $act (keys %$act_href) {
		my $ctr = 1;
		my $phrases = $filter_yaml->{$act};
		foreach my $phrase (sort { $phrases->{$b} <=> $phrases->{$a} } keys %$phrases) {
			my $k = "p" . $ctr;
			if($ctr < 10) {
				$k = "p000" . $ctr;
			} elsif($ctr < 100) {
				$k = "p00" . $ctr;
			} elsif($ctr < 1000) {
				$k = "p0" . $ctr;
			}
			say " summary set; act[$act] wkey[$k] phrase[$phrase] NEW PHRASE ct[".$phrases->{$phrase}."]" if $detail_trace;
			$all_ydata->{SUMMARYDATA}->{wordcentered}->{$act}->{$k}->{phrase} = $phrase;
#			$_ydata->{wordcentered}->{$act}->{$k}->{phrase} = $phrase;
			$all_ydata->{SUMMARYDATA}->{wordcentered}->{$act}->{$k}->{count} = $phrases->{$phrase};
#			$_ydata->{wordcentered}->{$act}->{$k}->{count} = $filter_yaml->{$phrase};
			$ctr++;
			$pctr++;
		}
	}
	my $wctr = 0;
	foreach my $wordkey (keys %$word_href) {
		my $ctr = 1;
		my $words = $word_filter_yaml->{$wordkey};
		my $prefix = 'w';
		if($wordkey=~/^two/i) {
			$prefix = 'ww';
		}
		foreach my $word (sort { $words->{$b} <=> $words->{$a} } keys %$words) {
			my $k = $prefix . $ctr;
			if($ctr < 10) {
				$k = $prefix . "0000" . $ctr;
			} elsif($ctr < 100) {
				$k = $prefix . "000" . $ctr;
			} elsif($ctr < 1000) {
				$k = $prefix . "00" . $ctr;
			} elsif($ctr < 10000) {
				$k = $prefix . "0" . $ctr;
			}
			say " summary set; wordtype[$wordkey] wkey[$k] phrase[$word] NEW PHRASE ct[".$words->{$word}."]" if $detail_trace;
			$all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}->{$k}->{word} = $word;
			$all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}->{$k}->{count} = $words->{$word};
			$ctr++;
			$wctr++;
		}
	}

	say "updated summary data; act ct[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}})."] total phrases[$pctr] total words+[$wctr]" if $trace;

	foreach my $wordkey (keys %{$_ydata->{causeeffect}}) {
#		$word_href->{$wordkey} = 1;
		my $count = scalar(keys %{$all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}});
		my $prefix = 'if';
		my $ctr = 1;
		foreach my $wkey (sort { $a cmp $b } keys %{$_ydata->{causeeffect}->{$wordkey}}) {
#			my $word = $_ydata->{causeeffect}->{$wordkey}->{$wkey}->{phrase};
			my $k = $prefix . $ctr;
			if($ctr < 10) {
				$k = $prefix . "0000" . $ctr;
			} elsif($ctr < 100) {
				$k = $prefix . "000" . $ctr;
			} elsif($ctr < 1000) {
				$k = $prefix . "00" . $ctr;
			} elsif($ctr < 10000) {
				$k = $prefix . "0" . $ctr;
			}
			my $skey = $_ydata->{causeeffect}->{$wordkey}->{$wkey}->{sentencekeys};
			my ($blockey,$sentencekey) = split '__',$skey;
			my $sent = $phraseblocs->{$blockey}->{$sentencekey};
			if(!$sent) {
				die "bad key structure in phrase/sentence hash, skey[$skey]\n";
			}
#			my $index = $_ydata->{causeeffect}->{$wordkey}->{$wkey}->{index};
			$all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}->{$k}->{phrase} = $_ydata->{causeeffect}->{$wordkey}->{$wkey}->{phrase};
			$all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}->{$k}->{index} = $ctr;
			$all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}->{$k}->{sentence} = $sent;
			$ctr++;
		}
	}

	$filter_yaml = undef;
	$word_filter_yaml = undef;
	$act_href = undef;
	$word_href = undef;
	return;
}
sub summary_multi_yml_data {
	my ($peep,$all_ydata,$_ydata,$phraseblocs,$trace) = @_;

	my $detail_trace = 0;
	my $filter_yaml = {};
	my $act_href = {};
	my $word_filter_yaml = {};
	my $word_href = {};
#	my $ifthen_filter_yaml = {};
#	my $ifthen_href = {};
	
	say "Making summary Multi-data" if $trace;
	if(exists $all_ydata->{SUMMARYDATA}) {
		if(exists $all_ydata->{SUMMARYDATA}->{wordcentered}) {
			say "  old summary data; act ct[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}})."] word cts[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcounts}})."]" if $trace;
			foreach my $actkey (keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}}) {
				$act_href->{$actkey} = 1;
				foreach my $wkey (sort { $a cmp $b } keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}->{$actkey}}) {
					my $kkey = $all_ydata->{SUMMARYDATA}->{wordcentered}->{$actkey}->{$wkey}->{phrase};
					if(!exists $filter_yaml->{$actkey}->{$kkey}) {
						$filter_yaml->{$actkey}->{$kkey} = 0;
						say "   summary old; act[$actkey] wkey[$wkey] phrase[$kkey] NEW PHRASE ct[".$filter_yaml->{$actkey}->{$kkey}."]" if $detail_trace;
					}
					$filter_yaml->{$actkey}->{$kkey} = $filter_yaml->{$actkey}->{$kkey} + 1;
#					print "summary; act[$actkey] wkey[$wkey] phrase[$kkey] phrase ct[".$filter_yaml->{$kkey}."]\n" if $trace;
				}
			}
		}
		if(exists $all_ydata->{SUMMARYDATA}->{wordcounts}) {
			say "  old summary data; word cts[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcounts}})."]" if $trace;
			foreach my $wordkey (keys %{$all_ydata->{SUMMARYDATA}->{wordcounts}}) {
				$word_href->{$wordkey} = 1;
				foreach my $wkey (sort { $a cmp $b } keys %{$all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}}) {
					my $word = $all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}->{$wkey}->{word};
					$word_filter_yaml->{$wordkey}->{$word} = $all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}->{$wkey}->{count};
				
				}
			}
		}
#		if(exists $all_ydata->{SUMMARYDATA}->{causeeffect}) {
#			say "  old summary data; word cts[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{causeeffect}})."]" if $trace;
#			foreach my $ifkey (keys %{$all_ydata->{SUMMARYDATA}->{causeeffect}}) {
#				$ifthen_href->{$ifkey} = 1;
#				foreach my $wkey (sort { $a cmp $b } keys %{$all_ydata->{SUMMARYDATA}->{causeeffect}->{$ifkey}}) {
#					my $phrase = $all_ydata->{SUMMARYDATA}->{causeeffect}->{$ifkey}->{$wkey}->{phrase};
#					if(!exists $ifthen_filter_yaml->{$ifkey}->{$wkey}) {
#						$ifthen_filter_yaml->{$ifkey}->{$wkey} = 0;
#					}
#					$ifthen_filter_yaml->{$ifkey}->{$phrase} = $all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}->{$wkey}->{sentencekeys};
#				}
#			}
#		}
	}
	say "  new summary data; act ct[".scalar(keys %{$_ydata->{wordcentered}})."]" if $trace;
	foreach my $actkey (keys %{$_ydata->{wordcentered}}) {
		$act_href->{$actkey} = 1;
		foreach my $wkey (sort { $a cmp $b } keys %{$_ydata->{wordcentered}->{$actkey}}) {
			my $kkey = $_ydata->{wordcentered}->{$actkey}->{$wkey}->{phrase};
			if(!exists $filter_yaml->{$actkey}->{$kkey}) {
				$filter_yaml->{$actkey}->{$kkey} = 0;
				say "   summary new; act[$actkey] wkey[$wkey] phrase[$kkey] NEW PHRASE ct[".$filter_yaml->{$actkey}->{$kkey}."]" if $detail_trace;
			}
			$filter_yaml->{$actkey}->{$kkey} = $filter_yaml->{$actkey}->{$kkey} + 1;
#			$filter_yaml->{$kkey} = 0;
		}
	}
	foreach my $wordkey (keys %{$_ydata->{wordcounts}}) {
		$word_href->{$wordkey} = 1;
		foreach my $wkey (sort { $a cmp $b } keys %{$_ydata->{wordcounts}->{$wordkey}}) {
			my $word = $_ydata->{wordcounts}->{$wordkey}->{$wkey}->{word};
			if(!exists $word_filter_yaml->{$wordkey}->{$word}) {
				$word_filter_yaml->{$wordkey}->{$word} = 0;
			}
			$word_filter_yaml->{$wordkey}->{$word} = $word_filter_yaml->{$wordkey}->{$word} + $_ydata->{wordcounts}->{$wordkey}->{$wkey}->{count};
		}
	}

	my $pctr = 0;
	foreach my $act (keys %$act_href) {
		my $ctr = 1;
		my $phrases = $filter_yaml->{$act};
		foreach my $phrase (sort { $phrases->{$b} <=> $phrases->{$a} } keys %$phrases) {
			my $k = "p" . $ctr;
			if($ctr < 10) {
				$k = "p000" . $ctr;
			} elsif($ctr < 100) {
				$k = "p00" . $ctr;
			} elsif($ctr < 1000) {
				$k = "p0" . $ctr;
			}
			say " summary set; act[$act] wkey[$k] phrase[$phrase] NEW PHRASE ct[".$phrases->{$phrase}."]" if $detail_trace;
			$all_ydata->{SUMMARYDATA}->{wordcentered}->{$act}->{$k}->{phrase} = $phrase;
			$all_ydata->{SUMMARYDATA}->{wordcentered}->{$act}->{$k}->{count} = $phrases->{$phrase};
			$ctr++;
			$pctr++;
		}
	}
	my $wctr = 0;
	foreach my $wordkey (keys %$word_href) {
		my $ctr = 1;
		my $words = $word_filter_yaml->{$wordkey};
		my $prefix = 'w';
		if($wordkey=~/^two/i) {
			$prefix = 'ww';
		}
		foreach my $word (sort { $words->{$b} <=> $words->{$a} } keys %$words) {
			my $k = $prefix . $ctr;
			if($ctr < 10) {
				$k = $prefix . "0000" . $ctr;
			} elsif($ctr < 100) {
				$k = $prefix . "000" . $ctr;
			} elsif($ctr < 1000) {
				$k = $prefix . "00" . $ctr;
			} elsif($ctr < 10000) {
				$k = $prefix . "0" . $ctr;
			}
			say " summary set; wordtype[$wordkey] wkey[$k] phrase[$word] NEW PHRASE ct[".$words->{$word}."]" if $detail_trace;
			$all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}->{$k}->{word} = $word;
			$all_ydata->{SUMMARYDATA}->{wordcounts}->{$wordkey}->{$k}->{count} = $words->{$word};
			$ctr++;
			$wctr++;
		}
	}

	say "updated summary data; act ct[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}})."] total phrases[$pctr] total words+[$wctr]" if $trace;

	my $ifctr = 0;
	foreach my $wordkey (keys %{$_ydata->{causeeffect}}) {
		my $count = scalar(keys %{$all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}});
		my $prefix = 'if';
		my $ctr = 1;
		foreach my $wkey (sort { $a cmp $b } keys %{$_ydata->{causeeffect}->{$wordkey}}) {
			my $k = $prefix . $ctr;
			if($ctr < 10) {
				$k = $prefix . "0000" . $ctr;
			} elsif($ctr < 100) {
				$k = $prefix . "000" . $ctr;
			} elsif($ctr < 1000) {
				$k = $prefix . "00" . $ctr;
			} elsif($ctr < 10000) {
				$k = $prefix . "0" . $ctr;
			}
			my $skey = $_ydata->{causeeffect}->{$wordkey}->{$wkey}->{sentencekeys};
			my $sent = undef;
			if($skey=~/t(\d+)__s(\d+)/i) {
				my $blockkey = $1;
				my $sentencekey = $2;
				#my ($blockey,$sentencekey) = split '__',$skey;
#				$sent = $phraseblocs->{$blockkey}->{$sentencekey};
				$sent = $phraseblocs->{$blockkey}->{$peep}->{$sentencekey};
			}
			if(!$sent) {
				die "bad key structure in phrase/sentence hash, skey[$skey] peep[$peep] at line[".__LINE__."]\n";
			}
			$all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}->{$k}->{phrase} = $_ydata->{causeeffect}->{$wordkey}->{$wkey}->{phrase};
			$all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}->{$k}->{index} = $ctr;
			$all_ydata->{SUMMARYDATA}->{causeeffect}->{$wordkey}->{$k}->{sentence} = $sent;
			$ctr++;
			$ifctr++;
		}
	}
	if($ifctr) {
		say "  new summary cause&effect data; ctr[$ifctr] ifthen ct[".scalar(keys %{$_ydata->{causeeffect}->{ifthen}})."]" if $trace;
	}
	
	$filter_yaml = undef;
	$word_filter_yaml = undef;
	$act_href = undef;
	$word_href = undef;
	return;
}

sub coded_yml_data {
	my ($all_ydata,$ignore_words,$trace) = @_;

	my $detail_trace = 0;
	my $filter_yaml = {};
	my $ignore_ct = 0;
	say "Making some coded data" if $trace;
	if(exists $all_ydata->{SUMMARYDATA}) {
		if(exists $all_ydata->{SUMMARYDATA}->{wordcentered}) {
			say "  old coded data; act ct[".scalar(keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}})."]" if $trace;
			foreach my $actkey (keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}}) {
				foreach my $wkey (sort { $a cmp $b } keys %{$all_ydata->{SUMMARYDATA}->{wordcentered}->{$actkey}}) {
					my $phrase = $all_ydata->{SUMMARYDATA}->{wordcentered}->{$actkey}->{$wkey}->{phrase};

					my %partcts = ();
					my %newparts = ();
					my @lparts = split ' ',$phrase;
					for (my $ii=0; $ii<scalar(@lparts); $ii++) {
						if(exists $ignore_words->{$lparts[$ii]}) {
							## ignore this word
							$ignore_ct++;
							next;
						}
						if($lparts[$ii]=~/^$actkey$/i) {
							next;
						}
						if(!$lparts[$ii]) {
							## ignore any falsy values
							next;
						}
						my $len = length($lparts[$ii]);
						$partcts{$lparts[$ii]} = $len;
					}
					my $str = $actkey;
					my $ktr = 0;
					foreach my $word (sort { $partcts{$b} <=> $partcts{$a} } keys %partcts ) {
						my $k = $partcts{$word} . "__" . $word;
						$newparts{$k} = 1;
						$ktr++;
						if($ktr > 2) {
							last;
						}
					}
					foreach my $nword (sort { $newparts{$b} cmp $newparts{$a} } keys %newparts ) {
						my ($int,$word) = split '__',$nword;
						$str = $str . "_" . $word;
					}
					if(!exists $filter_yaml->{$actkey}->{$str}) {
						$filter_yaml->{$actkey}->{$str} = 0;
					}
					$filter_yaml->{$actkey}->{$str} = $filter_yaml->{$actkey}->{$str} + 1;
				}
				my $ctr = 1;
				my $phrases = $filter_yaml->{$actkey};
				foreach my $code (sort { $phrases->{$b} <=> $phrases->{$a} } keys %$phrases) {
					my $k = "c" . $ctr;
					if($ctr < 10) {
						$k = "c000" . $ctr;
					} elsif($ctr < 100) {
						$k = "c00" . $ctr;
					} elsif($ctr < 1000) {
						$k = "c0" . $ctr;
					}
					say " code set; act[$actkey] wkey[$k] code[$code] NEW CODE ct[".$phrases->{$code}."]" if $detail_trace;
					$all_ydata->{SUMMARYDATA}->{phrasecoding}->{$actkey}->{$k}->{code} = $code;
					$all_ydata->{SUMMARYDATA}->{phrasecoding}->{$actkey}->{$k}->{count} = $phrases->{$code};
					$ctr++;
				}
				say "  new for actkey[$actkey] set [".scalar(keys %{$all_ydata->{SUMMARYDATA}->{phrasecoding}->{$actkey}})."] codes" if $trace;
			}
		}
	}
	return;
}

sub make_string {
	my ($lines,$trace) = @_;

	my $ct = 1;
	my $parsestr = '';
	for (my $i=0; $i<scalar(@$lines); $i++) {
		if(!$lines->[$i]) {
			next;
		}
		$parsestr = $parsestr . $ct . $lines->[$i] . "\n";
		$ct++;
	}
	return $parsestr;
}

sub make_better_string {
	my ($ydata,$lines,$trace) = @_;

	my $trace_detail = 0;
	my $ct = 1;
	my $parsestr = '';
	for (my $i=0; $i<scalar(@$lines); $i++) {
		if(!$lines->[$i]) {
			next;
		}
		my $found = 0;
		say " yaml topics to check [".scalar(keys %{$ydata->{topics}})."]" if $trace_detail;
		foreach my $j (sort { $a <=> $b } keys %{$ydata->{topics}}) {
			my $topic = $ydata->{topics}->{$j}->{topic};
#			say " topic to check [".$topic."]" if $trace;
			my $lineUC = uc $lines->[$i];
			if($lineUC=~/^$topic$/) {
				$parsestr = $parsestr . $ct . "{TOPIC} " . $lines->[$i] . "\n";
#				say " text file, setting topic [".$parsestr."]" if $trace;
				$found = 1;
				last;
			}
		}
		if($found) {
			$ct++;
			next;
		}
		$parsestr = $parsestr . $ct . $lines->[$i] . "\n";
		$ct++;
	}
	####
	## do a final special character scrub
	####
	my $count = 0;
	my $re =    qr/
				([\[\]\"])
				(?(?{$count++})|(*FAIL))
			/x;
	$parsestr =~ s/$re//g;

	return $parsestr;
}
sub make_sentences_string {
	my ($file_codes,$filename,$ydata,$lines,$trace) = @_;

	my $trace_detail = 0;
	my $codes = $file_codes->{topic_coding};
	#say "topic codign [$file_codes] [".$codes."]";

	my $ct = 1;
	my $sentct = 0;
	my $parsestr = '';
	if(scalar(@$lines)) {
#		$parsestr = "    1File [" . $filename . "]. \n";
#		$ct++;
#		$parsestr = $parsestr . "    2Src [" . $filename . "]. \n";
#		$ct++;
	}
	my $running_topic = undef;
	for (my $i=1; $i<scalar(@$lines); $i++) {
		if(!$lines->[$i]) {
			next;
		}
		my $ktr = $ct;
		if($ct < 10) {
			$ktr = "    " . $ct;
		} elsif($ct < 100) {
			$ktr = "   " . $ct;
		} elsif($ct < 1000) {
			$ktr = "  " . $ct;
		} elsif($ct < 10000) {
			$ktr = " " . $ct;
		}
		my $found = 0;
		say " yaml topics to check [".scalar(keys %{$ydata->{topics}})."]" if $trace_detail;
		foreach my $j (sort { $a <=> $b } keys %{$ydata->{topics}}) {
			my $topic = $ydata->{topics}->{$j}->{topic};
			
			## config basic coding
			if(!exists $codes->{$topic}) {
				$codes->{$topic}->{main_code} = lc $topic;
				$codes->{$topic}->{code_qualifiers}->{1} = lc $topic;
				$codes->{$topic}->{alt_codes}->{1} = '';
			}

			my $lineUC = uc $lines->[$i];
			if($lineUC=~/^$topic$/) {
				$parsestr = $parsestr . $ktr . "[" . $lines->[$i] . "]. \n";
				$running_topic = $topic;
				$found = 1;
				last;
			}
		}
		if($found) {
			$ct++;
			$sentct = 0;
			next;
		}
		$parsestr = $parsestr . $ktr . $lines->[$i] . ". \n";

		## do some basic coding
		$sentct++;
		if($running_topic and exists $codes->{$running_topic}) {
			$codes->{$running_topic}->{sentence_count} = $sentct;
			if(exists $codes->{$running_topic}->{char_density}) {
				delete $codes->{$running_topic}->{char_density};
			}
		}

		$ct++;
	}

	## add a newline at end to match AQUAD files
	$parsestr = $parsestr . "\n";

	return $parsestr;
}
sub make_multi_sentences_string {
	my ($file_codes,$filename,$ydata,$lines,$trace) = @_;

	my $trace_detail = 0;
	my $codes = $file_codes->{topic_coding};

	my $ct = 1;
	my $sentct = 0;
	my $parsestr = '';
	if(scalar(@$lines)) {
#		$parsestr = "    1File [" . $filename . "]. \n";
#		$ct++;
#		$parsestr = $parsestr . "    2Src [" . $lines->[0] . "]. \n";
#		$ct++;
	}
	my $running_topic = undef;
	for (my $i=1; $i<scalar(@$lines); $i++) {
		if(!$lines->[$i]) {
			next;
		}
		my $ktr = $ct;
		if($ct < 10) {
			$ktr = "    " . $ct;
		} elsif($ct < 100) {
			$ktr = "   " . $ct;
		} elsif($ct < 1000) {
			$ktr = "  " . $ct;
		} elsif($ct < 10000) {
			$ktr = " " . $ct;
		}
		my $found = 0;
		say " yaml topics to check [".scalar(keys %{$ydata->{topics}})."]" if $trace_detail;
		foreach my $j (sort { $a <=> $b } keys %{$ydata->{topics}}) {
			my $topic = $ydata->{topics}->{$j}->{topic};

			## verify topic data exists
			my $codeavail = 1;
			my $sents = $ydata->{topics}->{$j}->{sentences};
			if(!scalar(keys %$sents)) {
				$codeavail = 0;
			}
			if(scalar(keys %$sents) == 1) {
				foreach my $k (sort { $a <=> $b } keys %$sents) {
					if(!$sents->{$k}) {
						$codeavail = 0;
					}
				}
			}

			## config basic coding
			if($codeavail) {
				if(!exists $codes->{$topic}) {
					$codes->{$topic}->{main_code} = lc $topic;
					$codes->{$topic}->{code_qualifiers}->{1} = lc $topic;
					$codes->{$topic}->{alt_codes}->{1} = '';
				}
			}
			
			my $lineUC = uc $lines->[$i];
			if($lineUC=~/^$topic$/) {
				$parsestr = $parsestr . $ktr . "[" . $lines->[$i] . "]. \n";
				$running_topic = $topic;
				$found = 1;
				last;
			}
		}
		if($found) {
			$ct++;
			$sentct = 0;
			next;
		}
		$parsestr = $parsestr . $ktr . $lines->[$i] . ". \n";
		
		## do some basic coding
		$sentct++;
		if($running_topic and exists $codes->{$running_topic}) {
			$codes->{$running_topic}->{sentence_count} = $sentct;
			if(exists $codes->{$running_topic}->{char_density}) {
				delete $codes->{$running_topic}->{char_density};
			}
		}
		
		$ct++;
	}
	
	## add a newline at end to match AQUAD files
	$parsestr = $parsestr . "\n";

	return $parsestr;
}

sub dump_yaml_to_yml {
	my ($ydata,$yml_dir,$yamlfile,$trace) = @_;

	say "Dumping ALL to [$yamlfile]" if $trace;
	my $dfile = $yml_dir . $yamlfile;
	my $d = DumpFile($dfile, $ydata);

	if(exists $ydata->{FILEDATA}) {
		foreach my $findex (sort {$a eq $b} keys %{$ydata->{FILEDATA}}) {
			my $_ydata = $ydata->{FILEDATA}->{$findex};
			my $filename = $_ydata->{file};
			my @fparts = split '_', $filename;
			my $file = undef;
			for (my $i=0; $i<scalar(@fparts); $i++) {
				if($i==0) {
					$file = $fparts[$i];
					next;
				}
				$file = $file . "_" . $fparts[$i];
			}
			if(!defined $file) {
				next;
			}
			$file = lc $file;
			$file = $file . ".yml";
			$_ydata->{file} = $file;

			say "Dumping file[$file] at index[$findex] to yaml" if $trace;
			my $sfile = $yml_dir . $file;
			my $s = DumpFile($sfile, $_ydata);
		}
	}

	if(exists $ydata->{SUMMARYDATA}) {
		my $_ydata = $ydata->{SUMMARYDATA};
		my $file = 'summary_data.yml';
		say "Dumping summary data file[$file] to yaml" if $trace;
		my $sfile = $yml_dir . $file;
		my $s = DumpFile($sfile, $_ydata);
	}

	return 1;
}
sub dump_coding_to_yml {
	my ($ydata,$yml_dir,$yamlfile,$trace,$trace_more) = @_;

	say "Dumping Data_Coding, key ct[".scalar(keys %$ydata)."] to [$yamlfile]" if $trace;
	my $dfile = $yml_dir . $yamlfile;
	my $d = DumpFile($dfile, $ydata);
	if($trace_more) {
		say "Dumping Data_Coding, key ct[".scalar(keys %$ydata)."] to [$yamlfile] success[$d] dir[$yml_dir]";
	}
	return 1;
}
sub dump_recovery_file_to_yml {
	my ($ydata,$base_dir,$yamlfile,$trace) = @_;
	say "Dumping PrevData to DTG file in Recovery dir [$yamlfile]" if $trace;
	my $dfile = $base_dir . $recover_dir . $yml_dir . $yamlfile;
	my $d = DumpFile($dfile, $ydata);
	return 1;
}
sub dump_str_to_file {
	my ($fdata,$dir,$file,$iname,$trace) = @_;

	say "Dumping [$iname] to [$file]" if $trace;
	my $dfile = $dir . $file;
	my $afile = $cod_dir . "all_data-{s pS}.txt";

	open AFILE, ">$dfile" or die $!;
	print AFILE $fdata;
	close AFILE;

	print "Wrote test file [$afile] for [$iname] data\n" if $trace;

	return 1;
}

sub text_build {
	my ($file_codes,$ydata,$lines,$trace) = @_;
	
	my $detail_trace = 0;
	my $codes = $file_codes->{topic_coding};
	my $scodes = {};
#	if(!exists $file_codes->{sentences}) {
		$file_codes->{sentences} = $scodes;
#	}
#	$scodes = $file_codes->{sentences};
	my $bycodes = {};
		$file_codes->{by_codes} = $bycodes;
	my $tpcodes = {};
		$file_codes->{topics} = $tpcodes;

	my $max_line_length = 500;
	if(exists $pre_text_config->{ascii_line_limit} and $pre_text_config->{ascii_line_limit}) {
		$max_line_length = $pre_text_config->{ascii_line_limit};
	}
	my $aquad_pre_line_chars = 10;
	my $lctr = 1;
	my $char_tally = 0;
	my @popoff_list = ();
	say "REmaking text file from _ydata phrases, ct[".scalar(keys %{$ydata->{topics}})."]" if $trace;
	foreach my $j (sort { $a <=> $b } keys %{$ydata->{topics}}) {
		my $topic = $ydata->{topics}->{$j}->{topic};
		$tpcodes->{$topic} = $j;
		my $sents = $ydata->{topics}->{$j}->{sentences};
		my $maincode = lc $topic;
		if(exists $codes->{$topic}) {
			$maincode = $codes->{$topic}->{main_code};
		}
		say "  build[$j] topic[$topic] sentences ct[".scalar(keys %{$sents})."]" if $detail_trace;

		$lines->[$lctr] = "[" . $topic . "]. ";
		my $test = "[" . $topic . "]. ";
		$char_tally = $char_tally + length($test) + $aquad_pre_line_chars;
		my $pre_test = "[" . $topic . "]. ";
#		print "  remake; [$j] topic[$topic] " if $detail_trace;

		my $lstart = $lctr;
		
		my $ctr = 0;
		my $octr = 0;
		my $block_ct = 1;
		if(!scalar(keys %$sents)) {
			$block_ct = 0;
		}
		my $char_ct = 0;
		foreach my $k (sort { $a <=> $b } keys %$sents) {
			if(scalar(keys %$sents) == 1) {
				if(!$sents->{$k}) {
					$block_ct = 0;
					last;
				}
			}
			if(!defined($sents->{$k})) {
				say "  no sentence at index[$k]" if $detail_trace;
			}
			if(!defined($char_ct)) {
				say "  no char count at index[$k]" if $detail_trace;
			}
			my @w = split ' ',$sents->{$k};
			if(scalar(@w)) {
				my $key = "t" . $j . "s" . $k;
				$scodes->{$key}->{words} = scalar(@w);
				$scodes->{$key}->{chars} = length($sents->{$k});
				$scodes->{$key}->{begin_char_ct} = $char_ct;
				$scodes->{$key}->{sentence} = $sents->{$k};

				$scodes->{$key}->{codes}->{1} = $maincode;
				if(!exists $bycodes->{$maincode}) {
					$bycodes->{$maincode}->{words} = 0;
					$bycodes->{$maincode}->{chars} = 0;
				}
				$bycodes->{$maincode}->{words} = $bycodes->{$maincode}->{words} + scalar(@w);
				$bycodes->{$maincode}->{chars} = $bycodes->{$maincode}->{chars} + length($sents->{$k});
				my $c_ctr = 1;
				if(exists $codes->{$topic}->{alt_codes}) {
					foreach my $cct (sort {$a <=> $b} keys %{$codes->{$topic}->{alt_codes}}) {
						if(!$codes->{$topic}->{alt_codes}->{$cct}) {
							next;
						}
						my $cod = $codes->{$topic}->{alt_codes}->{$cct};
						$scodes->{$key}->{codes}->{$c_ctr} = $cod;
						if(!exists $bycodes->{$cod}) {
							$bycodes->{$cod}->{chars} = 0;
							$bycodes->{$cod}->{words} = 0;
						}
						$bycodes->{$cod}->{chars} = $bycodes->{$cod}->{chars} + length($sents->{$k});
						$bycodes->{$cod}->{words} = $bycodes->{$cod}->{words} + scalar(@w);
						$c_ctr++;
					}
				}
				if(exists $codes->{$topic}->{code_qualifiers}) {
					foreach my $cct (sort {$a <=> $b} keys %{$codes->{$topic}->{code_qualifiers}}) {
						if(!$codes->{$topic}->{code_qualifiers}->{$cct}) {
							next;
						}
						my $cod = $codes->{$topic}->{code_qualifiers}->{$cct};
						my $cod2 = $maincode . "::" . $codes->{$topic}->{code_qualifiers}->{$cct};
						$scodes->{$key}->{codes}->{$c_ctr} = $codes->{$topic}->{code_qualifiers}->{$cct};
						if(!exists $bycodes->{$cod}) {
							$bycodes->{$cod}->{chars} = 0;
							$bycodes->{$cod}->{words} = 0;
						}
						$bycodes->{$cod}->{chars} = $bycodes->{$cod}->{chars} + length($sents->{$k});
						$bycodes->{$cod}->{words} = $bycodes->{$cod}->{words} + scalar(@w);
						if(!exists $bycodes->{$cod2}) {
							$bycodes->{$cod2}->{chars} = 0;
							$bycodes->{$cod2}->{words} = 0;
						}
						$bycodes->{$cod2}->{chars} = $bycodes->{$cod2}->{chars} + length($sents->{$k});
						$bycodes->{$cod2}->{words} = $bycodes->{$cod2}->{words} + scalar(@w);
						$c_ctr++;
					}
				}
			}
			$char_ct = $char_ct + length($sents->{$k}) + 2;
			$test = $test . $sents->{$k} . ". ";
			if(length($test) > $max_line_length) {
				$lines->[$lctr] = $pre_test;
				$test = $sents->{$k} . ". ";
				$lctr++;
				$octr++;
				$block_ct++;
				$char_ct = $char_ct + $aquad_pre_line_chars + 1; ## add for newline char
			}
			$pre_test = $test;
			$lines->[$lctr] = $test;
			$ctr++;
		}
		if($block_ct) {

			say "    topic text available, topic coded[$topic] begin char str at[$char_tally]" if $detail_trace;
			## setup cleaning of old topics 
			push @popoff_list,$topic;
			
			## config basic coding
			if(!exists $codes->{$topic}) {
				$codes->{$topic}->{main_code} = lc $topic;
				$codes->{$topic}->{code_qualifiers}->{1} = lc $topic;
				$codes->{$topic}->{alt_codes}->{1} = '';
			}
			$codes->{$topic}->{chars}->{begin} = $char_tally;
			$ydata->{topics}->{$j}->{chars_count} = $char_ct;
			$codes->{$topic}->{chars}->{count} = $char_ct;
			$codes->{$topic}->{line}->{start} = $lstart;
			$codes->{$topic}->{line}->{end} = $lctr;
			if(exists $ydata->{topics}->{$j}->{total_words}) {
				$codes->{$topic}->{unique_words} = $ydata->{topics}->{$j}->{unique_words};
				$codes->{$topic}->{total_words} = $ydata->{topics}->{$j}->{total_words};
			}
		}
		
		## clean data coding file
		if(!$block_ct) {
			if(exists $codes->{$topic}) {
				foreach my $kk (keys %{$codes->{$topic}}) {
					if($codes->{$topic}->{$kk}=~/HASH/i) {
						foreach my $kkk (keys %{$codes->{$topic}->{$kk}}) {
							say "    deleting topic[$topic] at [$kk] [$kkk]";
							delete $codes->{$topic}->{$kk}->{$kkk};
						}
					}
					delete $codes->{$topic}->{$kk};
				}
				delete $codes->{$topic};
			}
		}
		my $pre_char = $char_tally;		
		$char_tally = $char_tally + $char_ct + 0; ## add for newline char
		say "    lstart[$lstart] lend[$lctr] begin[$pre_char] str char ct[$char_ct] new total chars[$char_tally]" if $detail_trace;
		$lctr++;
	}
	say "topics coded [".scalar(keys %$codes)."]" if $trace;
	my @dirty_list = ();
	foreach my $t (keys %$codes) {
		my $found = 0;
		for (my $i=0; $i<scalar(@popoff_list); $i++) {
			if($t eq $popoff_list[$i]) {
				$found = 1;
				last;
			}
		}
		if(!$found) {
			push @dirty_list, $t;
			say "    this topic [".$t."] is no longer valid. removing from codes";
		}
	}
	for (my $i=0; $i<scalar(@dirty_list); $i++) {
		my $t = $dirty_list[$i];
		if(exists $codes->{$t}) {
			foreach my $kk (keys %{$codes->{$t}}) {
				if($codes->{$t}->{$kk}=~/HASH/i) {
					foreach my $kkk (keys %{$codes->{$t}->{$kk}}) {
						say "    deleting topic[$t] at [$kk] [$kkk]";
						delete $codes->{$t}->{$kk}->{$kkk};
					}
				}
				delete $codes->{$t}->{$kk};
			}
			delete $codes->{$t};
		}
	}
#	my $codes = $file_codes->{topic_coding};
	return 1;
}
sub write_atx_file {
	my ($file_codes,$ydata,$lines,$trace) = @_;
	
	my $detail_trace = 0;
	my $codes = $file_codes->{topic_coding};

	say "fetching data for atx file, lines set[".scalar(@$lines)."]" if $trace;
	if(!scalar(@$lines)) {
		&text_build($file_codes,$ydata,$lines,$trace);
	}
	
	my $file_text = '';
	my $start = 1;
	if(scalar(@$lines)) {
		if(defined $lines->[0]) {
			$file_text = $lines->[0];
			say "line 0 defined, writing to start of atx file str" if $trace;
		} elsif(defined $lines->[1]) {
			$file_text = $lines->[1];
			$start = 2;
			say "line 0 NOT defined, but line 1 defined, start write of atx file str at line 1." if $trace;
		} else {
			die "some problem with data index for writing atx file";
		}
	}
	for (my $i=$start; $i<scalar(@$lines); $i++) {
		$file_text = $file_text . "\n" . $lines->[$i];
	}

	## add a newline at end to match AQUAD files
	$file_text = $file_text . "\n";

	return $file_text;

}
sub rewrite_text_file {
	my ($file_codes,$ydata,$lines,$trace) = @_;
	
	my $detail_trace = 0;
	my $codes = $file_codes->{topic_coding};

	say "fetching data for text file, lines set[".scalar(@$lines)."]" if $trace;
	if(!scalar(@$lines)) {
		&text_build($file_codes,$ydata,$lines,$trace);
	}
	
	my $file_text = '';
	if(scalar(@$lines)) {
		$file_text = $lines->[0];
	}
	for (my $i=1; $i<scalar(@$lines); $i++) {
		$file_text = $file_text . $lines->[$i];
	}

	return $file_text;
}
sub rewrite_text_file2 {
	my ($file_codes,$ydata,$trace) = @_;
	
	my $detail_trace = 0;
	my $codes = $file_codes->{topic_coding};

	my $file_text = '';
	my @lines = ();
	my $max_line_length = 500;
	if(exists $pre_text_config->{ascii_line_limit} and $pre_text_config->{ascii_line_limit}) {
		$max_line_length = $pre_text_config->{ascii_line_limit};
	}
	my $lctr = 0;
	say "REmaking text file from _ydata phrases, ct[".scalar(keys %{$ydata->{topics}})."]" if $trace;
	foreach my $j (sort { $a <=> $b } keys %{$ydata->{topics}}) {
		my $topic = $ydata->{topics}->{$j}->{topic};
		my $sents = $ydata->{topics}->{$j}->{sentences};
		say "  yaml topic[$topic] sentences ct[".scalar(keys %{$sents})."]" if $detail_trace;

		$lines[$lctr] = "[" . $topic . "]. ";
		my $test = "[" . $topic . "]. ";
		my $pre_test = "[" . $topic . "]. ";
		print "  remake; [$j] topic[$topic] " if $detail_trace;
		my $ctr = 0;
		my $octr = 0;
		my $block_ct = 1;
		foreach my $k (sort { $a <=> $b } keys %$sents) {
			$test = $test . $sents->{$k} . ". ";
			if(length($test) > $max_line_length) {
				$lines[$lctr] = $pre_test;
				$test = $sents->{$k} . ". ";
				$lctr++;
				$octr++;
				$block_ct++;
			}
			$pre_test = $test;
			$lines[$lctr] = $test;
			$ctr++;
#			$block_ct++;
		}
	
		## config basic coding
		if(!exists $codes->{$topic}) {
			$codes->{$topic}->{main_code} = lc $topic;
			$codes->{$topic}->{code_qualifiers}->{1} = lc $topic;
			$codes->{$topic}->{alt_codes}->{1} = '';
			$codes->{$topic}->{line}->{start} = $lctr+1;
		}
		if(exists $codes->{$topic}) {
			$codes->{$topic}->{block_size} = $block_ct;
		}

		print "std lines[$ctr] over lines[$octr]\n" if $detail_trace;
		$lctr++;
	}
	if(scalar(@lines)) {
		$file_text = $lines[0];
	}
	for (my $i=1; $i<scalar(@lines); $i++) {
		$file_text = $file_text . "\n" . $lines[$i];
	}

	return $file_text;
}

sub rejoin_text_file {
	my ($file_codes,$ydata,$trace) = @_;
	
	my $detail_trace = 0;
	my $codes = $file_codes->{topic_coding};

	my $file_text = '';
	my @lines = ();
	my $max_line_length = 500;
	if(exists $pre_text_config->{ascii_line_limit} and $pre_text_config->{ascii_line_limit}) {
		$max_line_length = $pre_text_config->{ascii_line_limit};
	}
	my $lctr = 0;
	say "REjoining phrases from _ydata phrases, ct[".scalar(keys %{$ydata->{topics}})."]" if $trace;
	foreach my $j (sort { $a <=> $b } keys %{$ydata->{topics}}) {
		my $topic = $ydata->{topics}->{$j}->{topic};
		my $sents = $ydata->{topics}->{$j}->{sentences};
		say "  yaml topic[$topic] sentences ct[".scalar(keys %{$sents})."]" if $detail_trace;

		$lines[$lctr] = "[" . $topic . "]. ";
		my $test = "[" . $topic . "]. ";
		my $pre_test = "[" . $topic . "]. ";
		print "  remake; [$j] topic[$topic] " if $detail_trace;
		my $ctr = 0;
		my $octr = 0;
		my $block_ct = keys %$sents;
		foreach my $k (sort { $a <=> $b } keys %$sents) {
			if(!$sents->{$k}) {
				$block_ct--;
				next;
			}
			$test = $test . $sents->{$k} . ". ";
			if(length($test) > $max_line_length) {
				$lines[$lctr] = $pre_test;
				$test = $sents->{$k} . ". ";
				$lctr++;
				$octr++;
				$block_ct++;
			}
			$pre_test = $test;
			$lines[$lctr] = $test;
			$ctr++;
		}

		## config basic coding
		if($block_ct > 0) {
			if(!exists $codes->{$topic}) {
				$codes->{$topic}->{main_code} = lc $topic;
				$codes->{$topic}->{code_qualifiers}->{1} = lc $topic;
				$codes->{$topic}->{alt_codes}->{1} = '';
			}
			if(exists $codes->{$topic}) {
				$codes->{$topic}->{block_size} = $block_ct;
			}
		}

		print "std lines[$ctr] over lines[$octr]\n" if $detail_trace;
		$lctr++;
	}
	if(scalar(@lines)) {
		$file_text = $lines[0];
	}
	for (my $i=1; $i<scalar(@lines); $i++) {
		$file_text = $file_text . "\n" . $lines[$i];
	}

	return $file_text;
}

sub make_new_aco_file {
	####
	## .aco file format
	## fixed field sizes [field size, field type], 5x fields
	## (10x, start line num)(10x, end line num)(60x, description)(10x, char count start location)(10x, chars in segment)
	####
	my ($file_codes,$iname,$trace,$trace_more) = @_;
	
	my $tcodes = $file_codes->{sentences};
	my $parsed_sent_info = $data_postparse->{post_parse}->{$iname}->{atx_txt}->{sentence_info};
	my $filedata = {};
	
	my $detail_trace = 0;
	if($trace_more) {
		$detail_trace = 1;
	}
	## make padding
	my $padding = "";
	for (my $i=0; $i<60; $i++) {
		$padding = $padding . ' ';
	}
	say "make aco file, tcodes[".scalar(keys %$tcodes)."] length padding[".length($padding)."]" if $trace;
	my $start = 0;
	my $end = 0;
	my $start_total = 1;
	my $char_count = 1;
	my $description = "data code";
	
	my $sorter = {};
	my $cctr = 0;
	foreach my $sent (keys %$tcodes) {
		if($sent=~/^t(\d+)s(\d+)/i) {
			my $t = $1;
			my $s = $2;
			$sorter->{$t}->{$s} = $sent;
			$cctr++;
		}
	}
	say "post sorter, [$cctr] sentences";
	my $char_counter = 0;
	my $char_offset = 0;
	
	my $codehref = {};
	if(exists $file_codes->{code_rack}) {
		$codehref = $file_codes->{code_rack};
	}
	
	foreach my $tindex (sort {$a <=> $b} keys %$sorter) {
		foreach my $sindex (sort {$a <=> $b} keys %{$sorter->{$tindex}}) {
			my $skey = $sorter->{$tindex}->{$sindex};
#			my $tskey = "t" . $tindex . "s" . $skey;
			my $tskey = $skey;

			$start++;
			$end++;
#			my $start_char = $tcodes->{$skey}->{begin_char_ct};
			my $start_char = $parsed_sent_info->{$tskey}->{chars}->{begin};
			my $line_count = $parsed_sent_info->{$tskey}->{line}->{count};
			$char_count = length($tcodes->{$skey}->{sentence});
			if($start_char < $char_counter) {
				if($start_char < 10) {
					$char_offset = $char_counter;
				}
			}
			$char_counter = $start_char + $char_offset;

			my $start_form = &pad_prefix($start);
			my $end_form = &pad_prefix($end);
			my $total_form1 = &pad_prefix($start_char);
			my $total_form = &pad_prefix($char_counter);
			my $char_form = &pad_prefix($char_count);

			$tcodes->{$skey}->{overall_char_begin} = $char_counter;
			foreach my $cindex (keys %{$tcodes->{$skey}->{codes}}) {
				my $code = $tcodes->{$skey}->{codes}->{$cindex};
				$codehref->{$code}->{$start}->{char_begin} = $char_counter;
				$codehref->{$code}->{$start}->{char_count} = $char_count;
				$codehref->{$code}->{$start}->{line_count} = $line_count;
				$code = $code . $padding;
				my $field = substr($code,0,60);
				my $line = $start_form . $end_form . $field . $total_form1 . $total_form . $char_form . "__x";
#				say "  line[".$line."]" if $trace;
#				$filedata->{$start}->{$end}->{$line} = 1;
			}
		}
	}
	if(!exists $file_codes->{code_rack}) {
		$file_codes->{code_rack} = $codehref;
	}
	$codes_dirty->{re_codes} = 1;

	my $ctr = 0;
	my $linerackdebug = 0;
	foreach my $codekey (sort {$a eq $b} keys %{ $file_codes->{code_rack} }) {
		my $prev_ct = undef;
		my $diff_ct = 0;
		my $store_char_ctr = undef;
		my $store_char_ct = undef;
		my $store_start_char_ctr = undef;
		my $store_start_line_ct = undef;
		foreach my $skey (sort {$a <=> $b} keys %{ $file_codes->{code_rack}->{$codekey} }) {
			my $begin = $file_codes->{code_rack}->{$codekey}->{$skey}->{char_begin};
			my $count = $file_codes->{code_rack}->{$codekey}->{$skey}->{char_count};
			my $line = $file_codes->{code_rack}->{$codekey}->{$skey}->{line_count};
			print "[$codekey] [$skey] begin[$begin] ct[$count] diff_ct[$diff_ct]\n" if $linerackdebug;
			if(!defined $prev_ct) {
				$prev_ct = $skey;
				$store_start_char_ctr = $begin;
				$store_start_line_ct = $skey;
				next;
			}
			my $diff = $skey - $prev_ct;
			if($diff==1) {
				$diff_ct++;
			print "[$codekey] [$skey] diff[$diff] prevct[$prev_ct] diff_ct[$diff_ct] stored start line[$store_start_line_ct]\n" if $linerackdebug;
				$prev_ct = $skey;
				next;
			}
			print "[$codekey] [$skey] diff[$diff] prevct[$prev_ct] diff_ct[$diff_ct] stored start line[$store_start_line_ct]\n" if $linerackdebug;
			if($diff_ct) {
				$file_codes->{line_rack}->{$codekey}->{$store_start_line_ct}->{line_end} = $prev_ct;
				$file_codes->{line_rack}->{$codekey}->{$store_start_line_ct}->{char_begin} = $store_start_char_ctr;
				my $char_diff = $file_codes->{code_rack}->{$codekey}->{$prev_ct}->{char_begin} - $store_start_char_ctr;
				$file_codes->{line_rack}->{$codekey}->{$store_start_line_ct}->{char_count} = $file_codes->{code_rack}->{$codekey}->{$prev_ct}->{char_count} + $char_diff;
				$diff_ct = 0;
			print "[$codekey] [$skey] diff[$diff] prevct[$prev_ct] diff_ct[$diff_ct] stored start line[$store_start_line_ct] char diff[$char_diff]\n" if $linerackdebug;
			}
			$prev_ct = $skey;
			$store_start_char_ctr = $begin;
			$store_start_line_ct = $skey;
			print "[$codekey] [$skey] diff[$diff] NEW prevct[$prev_ct] diff_ct[$diff_ct] stored start line[$store_start_line_ct] begin[$begin]\n" if $linerackdebug;
		}
		if($diff_ct) {
			$file_codes->{line_rack}->{$codekey}->{$store_start_line_ct}->{line_end} = $prev_ct;
			$file_codes->{line_rack}->{$codekey}->{$store_start_line_ct}->{char_begin} = $store_start_char_ctr;
			my $char_diff = $file_codes->{code_rack}->{$codekey}->{$prev_ct}->{char_begin} - $store_start_char_ctr;
			$file_codes->{line_rack}->{$codekey}->{$store_start_line_ct}->{char_count} = $file_codes->{code_rack}->{$codekey}->{$prev_ct}->{char_count} + $char_diff;
			print "[$codekey] out of loop diff_ct[$diff_ct] prevct[$prev_ct] stored start line[$store_start_line_ct] char diff[$char_diff]\n" if $linerackdebug;
		}
		$ctr++;
		if($linerackdebug and $ctr > 5) { last; }
		
	}
	foreach my $codekey (keys %{ $file_codes->{line_rack} }) {
		foreach my $skey (keys %{ $file_codes->{line_rack}->{$codekey} }) {
#			my $start_char = $parsed_sent_info->{$tskey}->{chars}->{begin};
#			my $char_ct = $parsed_sent_info->{$tskey}->{chars}->{count};
#			my $line_count = $parsed_sent_info->{$tskey}->{line}->{count};
			my $char_start = $file_codes->{line_rack}->{$codekey}->{$skey}->{char_begin};
			my $line_end = $file_codes->{line_rack}->{$codekey}->{$skey}->{line_end};
			my $char_ct = $file_codes->{line_rack}->{$codekey}->{$skey}->{char_count};
			my $start_form = &pad_prefix($skey);
			my $end_form = &pad_prefix($line_end);
			my $total_form = &pad_prefix($char_start);
#			my $total_form = &pad_prefix($char_counter);
			my $char_form = &pad_prefix($char_ct);

			my $startkey = $skey;
			if($startkey < 10) {
				$startkey = '00' . $startkey;
			} elsif($startkey < 100) {
				$startkey = '0' . $startkey;
			}

			my $code = $codekey . $padding;
			my $field = substr($code,0,60);
			my $line = $start_form . $end_form . $field . $total_form . $char_form . "__x";
#				say "  line[".$line."]" if $trace;
			$file_codes->{aco_rack}->{$startkey}->{$line_end}->{$codekey}->{line} = $line;
			$file_codes->{aco_rack}->{$startkey}->{$line_end}->{$codekey}->{char_begin} = $char_start;
			$file_codes->{aco_rack}->{$startkey}->{$line_end}->{$codekey}->{char_count} = $char_ct;
			$filedata->{$skey}->{$line_end}->{$line} = 1;
		}
	}
	
	my $filestr = '';
	foreach my $skey (sort {$a <=> $b} keys %$filedata) {
		foreach my $ekey (sort {$a <=> $b} keys %{$filedata->{$skey}}) {
			foreach my $lkey (sort {$a eq $b} keys %{$filedata->{$skey}->{$ekey}}) {
				my ($line,$throw) = split '__',$lkey;
				$filestr = $filestr . $line . "\n";
			}
		}
	}
	
	return $filestr;
}
sub make_aco_file {
	####
	## .aco file format
	## fixed field sizes [field size, field type], 5x fields
	## (10x, start line num)(10x, end line num)(60x, description)(10x, char count start location)(10x, chars in segment)
	####
	my ($file_codes,$trace,$trace_more) = @_;
	
	my $tcodes = $file_codes->{topic_coding};
	my $filedata = {};
	
	my $detail_trace = 0;
	if($trace_more) {
		$detail_trace = 1;
	}
	## make padding
	my $padding = "";
	for (my $i=0; $i<60; $i++) {
		$padding = $padding . ' ';
	}
	say "make aco file, tcodes[".scalar(keys %$tcodes)."] length padding[".length($padding)."]" if $trace;

	my $start = 1;
	my $end = 1;
	my $start_total = 1;
	my $char_count = 1;
	my $description = "data code";
	
	foreach my $topic (keys %$tcodes) {
		## make main code
		my $maincode = $tcodes->{$topic}->{main_code};
		my $testtopic = $topic;
		my @descripts = ();
		$description = $maincode . $padding;
		push @descripts,$description;
		foreach my $addkey (keys %{$tcodes->{$topic}->{code_qualifiers}}) {
			my $add = $tcodes->{$topic}->{code_qualifiers}->{$addkey};
			if(!$add) {
				next;
			}
			$add =~ s/[!\?\.]+//g;
			$testtopic =~ s/[!\?\.]+//g;
			#say "  maincode, tcode[".$topic."] test[$testtopic] add[$add] maincode[".$maincode."]" if $trace;
			if($add=~/^$testtopic$/i) {
				## skip...match to main code
				next;
			}
			my $maincode2 = $maincode . " - " . $add;
			$description = $maincode2 . $padding;
			push @descripts,$description;
			$add = $add . $padding;
			push @descripts,$add;
		}
		foreach my $akey (keys %{$tcodes->{$topic}->{alt_codes}}) {
			my $alt = $tcodes->{$topic}->{code_qualifiers}->{$akey};
			if(!$alt) {
				next;
			}
			$alt = $alt . $padding;
			push @descripts,$alt;
		}
		say "  maincode, tcode[".$topic."] test[$testtopic] maincode[".$maincode."]" if $detail_trace;

		if(!exists $tcodes->{$topic}->{line}->{start}) {
			die "bad keying for topic code setting";
		}
		$start = $tcodes->{$topic}->{line}->{start};
		$end = $tcodes->{$topic}->{line}->{end};
		if(!exists $tcodes->{$topic}->{chars}->{begin}) {
			die "bad keying for topic code setting";
		}
		$start_total = $tcodes->{$topic}->{chars}->{begin};
		$char_count = $tcodes->{$topic}->{chars}->{count};

		my $start_form = &pad_prefix($start);
		my $end_form = &pad_prefix($end);
		my $total_form = &pad_prefix($start_total);
		my $char_form = &pad_prefix($char_count);
		
		for (my $i=0; $i<scalar(@descripts); $i++) {
			my $field = substr($descripts[$i],0,60);
			my $line = $start_form . $end_form . $field . $total_form . $char_form . "_x";
			say "  line[".$line."]" if $detail_trace;
			$filedata->{$start}->{$end}->{$line} = 1;
		}
	}
	
	my $filestr = '';
	foreach my $skey (sort {$a <=> $b} keys %$filedata) {
		foreach my $ekey (sort {$a <=> $b} keys %{$filedata->{$skey}}) {
			foreach my $lkey (sort {$a eq $b} keys %{$filedata->{$skey}->{$ekey}}) {
				my ($line,$throw) = split '_',$lkey;
				$filestr = $filestr . $line . "\n";
#				say "  str[".$line."]" if $trace;
			}
		}
	}
	
	return $filestr;
}

sub make_analytics_file {
	my ($data_codes,$trace,$trace_more) = @_;
	
#	my $tcodes = $file_codes->{topic_coding};
	my $analcodes = $data_analysis->{by_code};
	
	my $detail_trace = 0;
	if($trace_more) {
		$detail_trace = 1;
	}

	my $sorter = {};
	foreach my $namecode (keys %$data_codes) {
		if($namecode=~/^runlinks$/i) {
			## skip
			next;
		}
		if(exists $data_codes->{$namecode}->{codes}) {
			if(exists $data_codes->{$namecode}->{codes}->{by_codes} and scalar(keys %{ $data_codes->{$namecode}->{codes}->{by_codes} })) {
		
				foreach my $code (keys %{$data_codes->{$namecode}->{codes}->{by_codes}}) {
					if(!exists $analcodes->{code_totals}->{$code}) {
						$analcodes->{code_totals}->{$code}->{chars} = 0;
						$analcodes->{code_totals}->{$code}->{words} = 0;
						$analcodes->{code_totals}->{$code}->{blocks} = 0;
					}
					$analcodes->{code_totals}->{$code}->{chars} = $analcodes->{code_totals}->{$code}->{chars} + $data_codes->{$namecode}->{codes}->{by_codes}->{$code}->{chars};
					$analcodes->{code_totals}->{$code}->{words} = $analcodes->{code_totals}->{$code}->{words} + $data_codes->{$namecode}->{codes}->{by_codes}->{$code}->{words};
					$analcodes->{code_totals}->{$code}->{blocks} = $analcodes->{code_totals}->{$code}->{blocks} + 1;
					$sorter->{code_totals}->{chars}->{$code} = $analcodes->{code_totals}->{$code}->{chars};
				}
			}
		}
		
		## loop sentences to make totals
		if(exists $data_codes->{$namecode}->{codes}) {
			if(exists $data_codes->{$namecode}->{codes}->{sentences} and scalar(keys %{ $data_codes->{$namecode}->{codes}->{sentences} })) {
		
				foreach my $skey (keys %{$data_codes->{$namecode}->{codes}->{sentences}}) {
					foreach my $cindex (keys %{$data_codes->{$namecode}->{codes}->{sentences}->{$skey}->{codes}}) {
						my $code = $data_codes->{$namecode}->{codes}->{sentences}->{$skey}->{codes}->{$cindex};
						if(!exists $analcodes->{code_mapping}->{$code}) {
							$analcodes->{code_mapping}->{$code}->{chars} = 0;
						}
						$analcodes->{code_mapping}->{$code}->{chars} = $analcodes->{code_mapping}->{$code}->{chars} + $data_codes->{$namecode}->{codes}->{sentences}->{$skey}->{chars};
						$sorter->{code_mapping}->{$code}->{sentences}->{$namecode}->{$skey} = 1;
					
					}
				}
			}
		}
	}
	my $ctr = 1;
	my $chars = $sorter->{code_totals}->{chars};
	foreach my $c (sort { $chars->{$b} <=> $chars->{$a} } keys %$chars) {
		my $k = "c" . $ctr;
		if($ctr < 10) {
			$k = "w000" . $ctr;
		} elsif($ctr < 100) {
			$k = "w00" . $ctr;
		} elsif($ctr < 1000) {
			$k = "w0" . $ctr;
		}
		$analcodes->{code_rankings}->{$k}->{$c} = $chars->{$c};
		$ctr++;
	}

	## loop sentences to link codes
#	$sorter->{code_mapping}->{$code}->{sentences}->{$namecode}->{$skey} = 1;
	foreach my $code (keys %{$sorter->{code_mapping}}) {
		my $tchars = $analcodes->{code_mapping}->{$code}->{chars};
		my $sort_mapper = $sorter->{code_mapping}->{$code};
		foreach my $name (keys %{$sort_mapper->{sentences}}) {
			foreach my $skey (keys %{$sort_mapper->{sentences}->{$name}}) {
				foreach my $cindex (keys %{$data_codes->{$name}->{codes}->{sentences}->{$skey}->{codes}}) {
					my $subcode = $data_codes->{$name}->{codes}->{sentences}->{$skey}->{codes}->{$cindex};
					if($code=~/^$subcode$/i) {
						## matching code...skip
						next;
					}
					if(!exists $analcodes->{code_mapping}->{$code}->{match_codes}->{$subcode}) {
						$analcodes->{code_mapping}->{$code}->{match_codes}->{$subcode}->{chars} = 0;
					}
					$analcodes->{code_mapping}->{$code}->{match_codes}->{$subcode}->{chars} = $analcodes->{code_mapping}->{$code}->{match_codes}->{$subcode}->{chars} + $data_codes->{$name}->{codes}->{sentences}->{$skey}->{chars};
		
				}
			}
		}
	}
	
#	return $analcodes;
	return $data_analysis;
}
sub write_per_code { ## method is OBE
	my ($cat,$taskid,$iname,$worksheet,$href,$heading_format1,$center_format,$trace) = @_;

	## make header row
	$worksheet->write(0, 0, "Code Name", $heading_format1);
	$worksheet->write(0, 2, "Count", $heading_format1);
	$worksheet->write(0, 3, "Dispersion", $heading_format1);
	$worksheet->write(1, 3, "Best Match", $heading_format1);
	$worksheet->write(0, 4, "Narrow", $heading_format1);
	$worksheet->write(0, 7, "Medium", $heading_format1);
	$worksheet->write(0, 10, "Wide", $heading_format1);
	$worksheet->write(1, 4, "Count", $heading_format1);
	$worksheet->write(1, 7, "Count", $heading_format1);
	$worksheet->write(1, 10, "Count", $heading_format1);
	$worksheet->write(1, 5, "Sum", $heading_format1);
	$worksheet->write(1, 8, "Sum", $heading_format1);
	$worksheet->write(1, 11, "Sum", $heading_format1);
	$worksheet->write(1, 6, "Mean", $heading_format1);
	$worksheet->write(1, 9, "Mean", $heading_format1);
	$worksheet->write(1, 12, "Mean", $heading_format1);
	$worksheet->write(0, 13, "Characters", $heading_format1);
	$worksheet->write(0, 14, "Words", $heading_format1);
	$worksheet->write(0, 15, "atx Lines", $heading_format1);
	$worksheet->write(1, 13, "Count", $heading_format1);
	$worksheet->write(1, 14, "Count", $heading_format1);
	$worksheet->write(1, 15, "Count", $heading_format1);

	$worksheet->set_column(0, 0, 40);
	$worksheet->set_column(1, 1, 3);
	$worksheet->set_column(3, 3, 15);
	$worksheet->set_column(13, 13, 14);
	$worksheet->set_column(14, 14, 14);
	$worksheet->set_column(15, 15, 14);

	my $rows = 0;
	if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion}) {
		my $row_ctr = 2;
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion} }) {
			$worksheet->write($row_ctr, 0, $code);
			$worksheet->write($row_ctr, 2, $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{total_count}, $center_format);
			
			my $n_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{count};
			if(!$n_ct) { $n_ct = 0; }
			my $m_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{count};
			if(!$m_ct) { $m_ct = 0; }
			my $w_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{count};
			if(!$w_ct) { $w_ct = 0; }
			my $best_match = 'narrow';
			if($w_ct > $m_ct and $w_ct > $n_ct) {
				$best_match = 'wide';
			} elsif($m_ct > $n_ct) {
				$best_match = 'medium';
			}
			$worksheet->write($row_ctr, 3, $best_match, $center_format);

			$worksheet->write($row_ctr, 4, $n_ct);
			$worksheet->write($row_ctr, 5, $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{sum});
			$worksheet->write($row_ctr, 6, $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{narrow}->{mean});

			$worksheet->write($row_ctr, 7, $m_ct);
			$worksheet->write($row_ctr, 8, $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{sum});
			$worksheet->write($row_ctr, 9, $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{medium}->{mean});
			
			$worksheet->write($row_ctr, 10, $w_ct);
			$worksheet->write($row_ctr, 11, $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{sum});
			$worksheet->write($row_ctr, 12, $href->{$iname}->{re_codes}->{linkage}->{dispersion}->{$code}->{stats}->{wide}->{mean});
			
			$worksheet->write($row_ctr, 13, $data_postparse->{post_parse}->{$iname}->{re_codes}->{clustering}->{code_stats}->{$code}->{chars}->{total_count});
			$worksheet->write($row_ctr, 14, $data_postparse->{post_parse}->{$iname}->{re_codes}->{clustering}->{code_stats}->{$code}->{words}->{total_count});
			$worksheet->write($row_ctr, 15, $data_postparse->{post_parse}->{$iname}->{re_codes}->{clustering}->{code_stats}->{$code}->{lines}->{total_count});
##			$data_postparse->{post_parse}->{$iname}->{re_codes}->{clustering}->{code_stats}->{$code}->{lines}->{total_count} = $data_postparse->{post_parse}->{$iname}->{re_codes}->{clustering}->{code_stats}->{$code}->{lines}->{total_count} + 1;

			$row_ctr++;
			$rows++;
		}
	}
	say "[cat:$cat][taskid:$taskid] iname[$iname] wrote [$rows] rows of codes to *per_code_stats* sheet";

	return $taskid;
}
sub write_linkage_updown { ## method is OBE
	my ($cat,$taskid,$iname,$worksheet,$href,$heading_format1,$heading_format2,$shade_format,$trace) = @_;

	
	$worksheet->write(0, 1, "Code Name", $heading_format1);
	$worksheet->set_column(0, 0, 4);
	$worksheet->set_column(1, 1, 40);
	$worksheet->write(0, 3, "Linked Code - Numbered 1-to-N", $heading_format2);

	my $rows = 0;
	my %code_ct = ();
	if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}) {
		my $limit_shading = scalar(keys %{ $data_coding->{$iname}->{re_codes}->{topics} });
		my $row_ctr = 2;
		my $col_start = 3;
		my $ctr = 1;
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown} }) {
			$code_ct{$code} = $ctr;
			$worksheet->write($row_ctr, 0, $ctr);
			$worksheet->write($row_ctr, 1, $code);
			$worksheet->write($row_ctr, 2, 'Linkage');
			$worksheet->write($row_ctr+1, 0, $ctr);
			$worksheet->write($row_ctr+1, 2, 'Nesting');
			$worksheet->write(1, $col_start+$ctr, $ctr, $heading_format1);
			$ctr++;
			$row_ctr = $row_ctr + 3;
		}
		$row_ctr = 2;
		foreach my $code (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown} }) {
			foreach my $code2 (keys %{ $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code} }) {

				if(!exists $code_ct{$code2}) {
					say "[cat:$cat][taskid:$taskid][write_linkage_updown] Warning! Missing code [$code] column ";
					next;
				}
				my $n_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{narrow}->{count};
				if(!$n_ct) { $n_ct = 0; }
				my $m_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{medium}->{count};
				if(!$m_ct) { $m_ct = 0; }
				my $w_ct = $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{wide}->{count};
				if(!$w_ct) { $w_ct = 0; }
				my $best_match = 'N: ' . $n_ct;
				if($w_ct > $m_ct and $w_ct > $n_ct) {
					$best_match = 'W: ' . $w_ct;
				} elsif($m_ct > $n_ct) {
					$best_match = 'M: ' . $m_ct;
				}

				my $col_ctr = $code_ct{$code2};
				$worksheet->write($row_ctr, $col_start+$col_ctr, $best_match);

				my $nesting = '';
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap}) {
					$nesting = 'Overlap: ' . $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_overlap};
				}
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_first_in_second} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_first_in_second}) {
					$nesting = 'Nested OVER';
				}
				if(exists $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_second_in_first} and $href->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$code2}->{stats}->{cat_complete_nesting_second_in_first}) {
					$nesting = 'Nested IN';
				}
				$worksheet->write($row_ctr+1, $col_start+$col_ctr, $nesting);

			}
			$row_ctr = $row_ctr + 3;
		}
	}

#	$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{cat_overlap} = $1;
#	$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{total_count} = $sum2;
#	$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{match_count} = $match_ct;
#	$statcodes->{$iname}->{re_codes}->{linkage}->{dispersion_updown}->{$code}->{$test_code}->{stats}->{no_match_count} = $no_match_ct;
	return $taskid;
}


sub kill_switch {
	my ($heap, $kernel) = @_[HEAP, KERNEL]; ##
#	print "!! Server kill has been requested\n" if $testing;
	######
	## Shutdown takes place via killing the listening socket
	######
	$heap->{shutdown_now} = 1;
	$heap->{socket_is_not_dead} = 1;
	$kernel->yield("socket_death");
}
sub wait_kill {
	$k_count++;
	print "timer fired! [$k_count] sess[$kill_session]\n" if $testing;
	if($kill_session==1) {
		print "last fire! [$kill_session][$k_count]\n" if $testing;
		print "closing connection...\n";
		$_[KERNEL]->delay(wait_kill => undef);
		$_[KERNEL]->yield("kill_switch");
		$kill_session=0;
		$k_count=0;
		return;
	}
	if($k_count>$kill_ct_delay) {
		$kill_session=1;
	}
	$_[KERNEL]->delay(wait_kill => 1);
}


