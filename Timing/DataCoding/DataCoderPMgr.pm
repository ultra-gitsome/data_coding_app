package DataCoderPMgr;
#######################################
#
#   This package creates a Data Coder specific Process Manager object 
#   Extends the methods in the base _pmgr class
#
#######################################

#use Moo;
use Moose;
use DateTime;
use YAML::XS qw(LoadFile DumpFile Load Dump);

extends 'ProcessManager';

#use IO::Socket;
#use IO::Socket::INET;
#use POE::Filter::Reference;

my $this_version = 0.200100;
my $publish_date = '2014.12.11';

has 'this_version' => (isa => 'Num', is => 'ro', default => 0.200100 );
has 'MY_SERVER_TYPE' => (isa => 'Str', is => 'rw',default => '_not_assigned_' );
has 'MYSERVERNUM' => (isa => 'Int', is => 'rw', default => 0 );
has 'MYNODALKEY' => (isa => 'Str', is => 'rw', default => 0 );

has 'RUNTIME_CARP' => (isa => 'Int', is => 'rw', default => 1 );
has 'TESTING_CARP' => (isa => 'Int', is => 'rw', default => 1 );
has 'FILE_LOAD_CARP' => (isa => 'Int', is => 'rw', default => 1 );
has 'CONFIG_SET_CARP' => (isa => 'Int', is => 'rw', default => 1 );
has 'SOCKET_DEBUG' => (isa => 'Int', is => 'rw', default => 0 );
has 'CONFIG_CONNECT_EXCHANGE' => (isa => 'Int', is => 'rw', default => 1 );

has 'HUB_START_SECS_UTC' => (isa => 'Int', is => 'rw');
has 'STARTTIME_SECS_UTC' => (isa => 'Int', is => 'rw');
has 'GLOBAL_PARAMETERS_LOADED' => (isa => 'Int', is => 'rw', default => 0);

has 'METHODS_SELECTIONS' => (isa => 'HashRef', is => 'rw', default => sub { {'events' => 'import_events','runners' => 'import_runners_json','courses' => 'import_courses_json','tags' => 'import_tags_json'} } );
has 'TS_PROCESS_OPTIONS' => (isa => 'HashRef', is => 'rw', builder => '__ts_process_options' );

## builder methods
sub __wx_gui_type_files {
	my $self = shift;
	my $bfile = $self->{TS_SYSTEM_WX_GUI_BASE_FILENAME};
	my $opt = {};
	$opt->{super} = $bfile . '_Super';
	$opt->{super2} = $bfile . '_WxPoeReader';
	$opt->{integrator} = $bfile . '_WxPoeIntegrator';
	$opt->{monitor} = $bfile . '_Monitor';
	$opt->{rmonitor} = $bfile . '_PoeReader';
	$opt->{laptracker} = $bfile . '_Laptracker';
	$opt->{datacoder} = $bfile . '_WxPoeDataCoder';
	return $opt;
}

## configuration methods

sub _signal_dtg_log_data {
	my $self = shift;
	my $file = shift; #$server_log_file
	my $h_ref = {};
	if(open(my $fh, '<', $file)) {
		$h_ref = LoadFile $file; 
	}
	if($h_ref!~/HASH/) {
		print "ERROR! Variable loaded for logging is not hash...\n";
		die "\n\tdying to fix...\n";
		return 0;
	}
	if(scalar(keys %$h_ref) > 10000) {
		my $server_log_file = localtime() . "_" . $file;
		my $u = DumpFile($server_log_file, $h_ref);
		foreach my $k (keys %$h_ref) {
			delete $h_ref->{$k};
		}
	}
	$self->{TS_SIGNAL_DTG_LOG_DATA} = $h_ref;
	return $h_ref;
}
sub _signal_runtime_log_data {
	my $self = shift;
	my $file = shift; #$server_log_file
	my $h_ref = {};
	if(open(my $fh, '<', $file)) {
		$h_ref = LoadFile $file; 
	}
	if($h_ref!~/HASH/) {
		print "ERROR! Variable loaded for logging is not hash...\n";
		die "\n\tdying to fix...\n";
		return 0;
	}
	if(scalar(keys %$h_ref) > 20000) {
		my $server_log_file = localtime() . "_" . $file;
		my $u = DumpFile($server_log_file, $h_ref);
		foreach my $k (keys %$h_ref) {
			delete $h_ref->{$k};
		}
	}
	$self->{TS_SIGNAL_RUNTIME_LOG_DATA} = $h_ref;
	return $h_ref;
}
sub _wx_gui_laptracker_conf_file {
	my $self = shift;
	####
	## Warning: only submit a BASE file name to this method! The server nodal id is glued onto the end.
	####
	my $file_suffix = $self->{TS_SYSTEM_WX_GUI_FILE_SUFFIX};
	my $Super = 'LapTracker';
	if(@_) {
		my $file_suffix = shift;
		$self->{TS_SYSTEM_WX_GUI_FILE_SUFFIX} = $file_suffix;
	}
	if(!$self->{TS_WX_SUPER_CONF_FILE}) {
		my $f = $self->__base_wx_gui_conf_file();
		my $dir = $self->_wx_disp_config_dir();
		$self->{TS_WX_SUPER_CONF_FILE} = $dir . $f . "_" . $Super . "_". $file_suffix . ".yml";
	}
	return $self->{TS_WX_SUPER_CONF_FILE};
}
sub ts_event_config_file {
	my $self = shift;
	my $file = $self->{TS_EVENT_CONFIG_FILE};
	if(!$file) {
		my $f = $self->{TS_EVENT_CONFIG_BASE_FILENAME};
		$f = $f . ".yml";
		my $dir = $self->_sync_hub_config_dir();
		$self->{TS_EVENT_CONFIG_FILE} = $dir . $f;
	}
	return $self->{TS_EVENT_CONFIG_FILE};
}


sub setup_events {
	my $self = shift;
	my $data = shift;
	my $my_server_href = shift;
	my $xh = shift;
	my $clear_data = 0; ## default is no
	if(exists $my_server_href->{clear_data}) { $clear_data = $my_server_href->{clear_data}; }
	my $debug = $self->{EVENT_DEBUG};
	my $runtime = $self->{RUNTIME_CARP};

	####
	## set a bunch of event/registration related info in node
	####
	print "\t\t[EVENT_CONF] == Setting event info..\n" if $runtime;

	####
	## check event server response for registration error
	## die on error because the configuration is broke
	####
	if(exists $data->{error}) {
		if($data->{error}) {
			die "\nEvent setup: " . $data->{error_message} . "\nStopping now.\n";
		}
	}
	
	if($runtime) {
		my $evts = $data->{events};
		print "\t\t[EVENT_CONF] Check eventcode list: ct[".scalar(keys %$evts)."]\n";
		while (my ($k,$v) = each (%$evts)) {
			print "\t\t\t[EVENT_Code] ecode: id[$k]\n";
			if($v=~/HASH/i) {
				while (my ($k2,$v2) = each (%$v)) {
					print "\t\t\t[EVENT] evt index: index[$k2]\n" if $debug;
					if($v2=~/HASH/i) {
						while (my ($k3,$v3) = each (%$v2)) {
							print "\t\t\t[EVENT] evt id: id[$k3] name[$v3]\n" if $debug;
						}
					}
				}
			}
		}
	}

	######
	## Reference _make_events in ts_event_server for key configuration
	######
	
	####
	## use an import method to update events in state manager - because of the key structure
	## ...not sure if it is a good idea to have this in two locations...
	####
	my $_smgr = $self->_stateManager();
	my $state_method = $self->select_dataload_method('events');
	my $ct = $_smgr->$state_method($data->{events},$data->{event_code});
	
	####
	## run node config update to reload data file and config options
	####
	my $paramlist = {};
	$paramlist->{my_server_type} = $my_server_href->{my_server_type};

	print "\t\t[EVENT_CONF] === server_num verifed and received from event_server[".$data->{server_num}."]\n" if $runtime;

	my $ecode = $data->{event_code};
	my $eids = $data->{events}->{$ecode};
	## current structure is one event per event code
	my $eid = undef;
	my $cs = undef;
	my $name = undef;
	my $tz = 0;
	my $tz_name = undef;
	my $dst = 1;
	my $tz_hr = 0;
	foreach my $_e (keys %$eids) {
		$eid = $_e;
		$name = $eids->{$_e}->{name};
		$tz = $eids->{$_e}->{time_zone};
		$tz_name = $eids->{$_e}->{time_zone_name};
		$dst = $eids->{$_e}->{dst_setting};
		$tz_hr = $eids->{$_e}->{time_zone_hour_offset}; ## hash key will be switched!
		$cs = $eids->{$_e}->{courses};
		print "\t\t\t[EVENT_CONF] name[$name] timezone offset[$tz_hr] course ct[".scalar(keys %$cs)."]\n" if $runtime;
	}
	$paramlist->{time_zone} = $tz;
	$paramlist->{time_zone_name} = $tz_name;
	$paramlist->{time_zone_offset_hours} = $tz_hr; ## new hash key!
	$paramlist->{dst_setting} = $dst;
	$self->add_event($ecode,$eid,$name);
	my $cct = scalar(keys %$cs);
	
	foreach my $cid (keys %$cs) {
		$cs->{$cid}->{total_ct} = $cct;
		print "\t\t\t[EVENT_COURSE_CONF] = COURSES: cindex[$cid]\n" if $debug;
	#	print "[EVENT_COURSE_CONF] = COURSES: cindex[$cid]\n";
#		$self->course_starts($cid,$tz_hr,$cs->{$cid});
	}
	$paramlist->{data} = $data;

	my $d_ct = $self->update_process_manager($paramlist,$xh);
		
	$xh->{param_updated} = $d_ct;
	$xh->{nodal_key} = $data->{nodal_key};
	$xh->{nodal_num} = $data->{server_num};
	
	return 1;
}
sub setup_runners {
	my $self = shift;
	my $data = shift;
#	my $debug = 0;
#	if(@_) { $debug = shift; }
	my $runtime = $self->{RUNTIME_CARP};

	print "\t\t[RUNNER_CONF] == Setting runner data..\n" if $runtime;
	my $state_method = $self->select_dataload_method('runners');
	my $_smgr = $self->_stateManager();
	my $d_ct = $_smgr->$state_method($data);

	print "  = [$d_ct] runners loaded\n" if $runtime;

	return $d_ct;
}


sub update_process_manager {
	my $self = shift;
	my $params = shift;
	my $xh = shift;
	my $_dmgr = $self->_dataManager();
	my $tsopts = $self->{TS_PROCESS_OPTIONS};
	my $fail = "\nCRITICAL ERROR! Missing ";
	if(!exists $params->{my_server_type}) {
		die $fail . "my_server_type; not submitted at line[".__LINE__."]\n";
	}
	my $debug = $self->{EVENT_DEBUG};
	my $runtime = $self->{RUNTIME_CARP};

	$self->{MY_SERVER_TYPE} = $params->{my_server_type};
	$tsopts->{server_type} = $params->{my_server_type};
	if(exists $params->{time_zone_offset_hours}) {
		print "\t\t[PMGR_SERVER_PARAMS] timezone update[".$params->{time_zone}."]\n" if $debug;
		$tsopts->{time_zone} = $params->{time_zone};
		$tsopts->{time_zone_name} = $params->{time_zone_name};
		$tsopts->{time_zone_offset_hours} = $params->{time_zone_offset_hours};
		$tsopts->{daylight_saving_time_toggle} = $params->{dst_setting};
		print "\t\t[PMGR_SERVER_PARAMS] time zone offset [".$params->{time_zone_offset_hours}."]\n" if $debug;
		if(exists $params->{use_data_mgr_obj} && $params->{use_data_mgr_obj}) {
			$_dmgr->timeZone($params->{time_zone_offset_hours});
			$_dmgr->isDST($params->{dst_setting});
		}
#	} else {
#		$tsopts->{time_zone} = $_dmgr->setTZ();
	}
#	if(exists $params->{clear_data} && $params->{clear_data}) {
#		my $_smgr = $self->_stateManager();
#		$_smgr->reload_prev_data(0);
#	}

	# set states
	my $data = $params->{data};
#	$self->hub_start_secs($data->{event_start_secs});
	$self->nodenumber($data->{nodenumber});
	$self->myhubid($data->{hub_id});
	print "\t\t[PMGR_SERVER_PARAMS] my hub id [".$data->{hub_id}."]\n" if $debug;
	$self->mysrvrnum($data->{server_num});
	$self->mynodaldescriptorkey($data->{nodal_key});
	print "\t\t[PMGR_SERVER_PARAMS] my nodal descriptor key [".$data->{nodal_key}."]\n" if $debug;
	$self->myhubdescriptorkey($data->{hub_key});
	print "\t\t[PMGR_SERVER_PARAMS] my hub descriptor key[".$data->{hub_key}."]\n" if $debug;
	if($data->{type_error}) {
		print "\nWARNING! Server typing problem in _pmgr! Data may not be handled correctly! [".$data->{type_error}."]\n\n";
	}
	
	
	if($self->{RUNTIME_CARP}) {
		print "\t\t[PMGR UPDATE Done] == {TSNet Event Registered}== node[".$data->{nodenumber}."] srvrnumber[".$data->{server_num}."] hubID[".$data->{hub_id}."] hubkey[".$data->{hub_key}."]\n"; 
	}
	
	return 1;
}
sub data_manager {
	my $self = shift;
	my $s = $self->{MANAGER_OBJECTS};
	if(@_) { $s->{data} = shift; }
	if(exists $s->{data}) {
		return $s->{data};
	}
	return undef;
}
sub server_load_prev_crush_all {
	my $self = shift;
	my $_dmgr = $self->_dataManager();
	my $_smgr = $self->_stateManager();
	my $monitor = 0;
	my $fail = "\nCRITICAL ERROR! Missing ";
	my $trace = 1;
	if(@_) {
		my $load = shift;
		if($load) { $monitor = 1; }
	}
	print "[RELOAD-CRUSH ALL] crushing all server loaded state data...\n" if $self->{RUNTIME_CARP};

	if(!$_dmgr) {
		die $fail . "DataManager object is not defined at line[".__LINE__."][".__PACKAGE__."]\n";
	}

	my $ts_data_flag = $_dmgr->get_option_value_make_data('ts_sourced_data_flag',$trace);
#	if(defined $ts_data_flag) {
#		print "[".__PACKAGE__."] setting *ts_source_data_flag* is defined [$ts_data_flag]\n";
#	}
	if(defined $ts_data_flag and $ts_data_flag) {
		if($self->ts_options("save_quick_data")) {
			print "...reload previously saved quick data...\n" if $self->{TESTING_CARP};
			$_dmgr->load_existing_quick_data();
		}
		if($self->ts_options("save_record_data")) {
#		$_dmgr->save_record_data();
		}
		if($self->ts_options("save_tracking_data")) {
#		$_dmgr->save_tracking_data();
		}
		if($self->ts_options("save_detail_data")) {
#		$_dmgr->save_detail_data();
		}
		$_dmgr->load_existing_dmgr_state_data();
		if($monitor) {
			$_dmgr->load_existing_dmgr_Mdata();
		}
		$_smgr->load_existing_smgr_state_data();
		return 1;
	}
	my $yaml_flag = $_dmgr->get_option_value_make_data('yaml_data_files_flag',$trace);
	if(defined $yaml_flag) {
		print "[".__PACKAGE__."] setting *yaml_data_files_flag* is defined [$yaml_flag]\n";
		my $yaml_src_file = $_dmgr->get_option_value_make_data('yaml_files_list_src_file',$trace);
		my $yaml_src_dir = $_dmgr->get_option_value_make_data('yaml_files_list_src_dir',$trace);
		print "[".__PACKAGE__."] setting *yaml_file_list_src_file* is defined [$yaml_src_file]\n" if $trace;
#		my $yml_dir = $self->yaml_datafiles_files_dir();
		$_dmgr->load_yaml_file_data($yaml_src_file,$yaml_src_dir,$trace);
		
	}
#	die;
	return 1;
}
sub reload_prev_data { ## default ARG will request a reload
	my $self = shift;
	my $reload = 1;
	my $me = 'RELOAD DATA/STATE';
	if(@_) {
		$reload = shift;
	}
	## check for using ts_data or turn_on_local_data_saves.
	print "[$me] setting check: use ts data[".$self->ts_options("use_ts_data")."] local saves[".$self->ts_options("turn_on_local_data_saves")."]\n";
	if(!$self->ts_options("use_ts_data") or !$self->ts_options("turn_on_local_data_saves")) {
		return 1;
	}
	## check for if this has already be done for this startup...
	if(!$reload) { 
		print "Clearing all previous data!...\n\n" if $self->{RUNTIME_CARP};
		return 1;
	}
#	print "...reload previous data...reload[$reload]\n" if $self->{TESTING_CARP};
	print "[$me] reloading previous data[$reload]\n" if $self->{RUNTIME_CARP};
	my $_smgr = $self->_stateManager();
	if(!$_smgr->prev_data_reload()) {
		if($reload) { ## may have multiple reload states in the future...
			if($reload > 1) {
				## push forward a flag to load monitor data
				$self->server_load_prev_crush_all(1);
			} else {
				$self->server_load_prev_crush_all();
			}
		}
		$_smgr->prev_data_reload(1)
	}
	return 1;
}


sub pipe_tracking_log_yml { ## for data tracking...
	my $self = shift;
	my $type = shift; ## type match to log file
	my $log_data = shift; ## data
	my $mkey = shift; ## main key to find data...key will not be logged
	my $dtg = localtime();
	## log file is keyed on dtg
	my $newentry = {};
	my $server_log_file = $self->{TS_LOG_FILE};
	if(!$server_log_file) {
		print "NOTICE! No tracking log file specified...nothing stored...\n\n";
		return 0;
	}
	if(!exists $log_data->{$mkey}) {
		print "\nERROR! Logging main key fails at pipe_log_yml, line[".__LINE__."]\n\n";
		return 0;
	}
	$newentry->{$dtg} = $log_data->{$mkey};

	if($type=~/^dtrack/i) {
		my $server_log_file = $self->_data_quality_tracking_file();
	} elsif($type=~/^tainted/i) {
		my $server_log_file = $self->_tainted_data_track_file();
	} elsif($type=~/^log/i) {
		my $server_log_file = $self->_tainted_data_track_file();
	} else {
		print "\nWARNING! No logging type specified...nothing done, line[".__LINE__."]\n\n";
		return 0;
	}
	my $h_ref = {};
	if(open(my $fh, '<', $server_log_file)) 
	{
		$h_ref = LoadFile $server_log_file; 
	}
	foreach my $k (keys %$newentry) {
		$h_ref->{$k} = $newentry->{$k};
	}
	my $u = DumpFile($server_log_file, $h_ref);

	return 1;
}






no Moose; # keywords are removed from the TSCourse package

1;  # so the require or use succeeds