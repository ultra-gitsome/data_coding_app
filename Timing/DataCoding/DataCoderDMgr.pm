package DataCoderDMgr;
#######################################
#
#   This package creates a Data Coder specific Data Manager object 
#   Extends the methods in the base _dmgr class
#
#######################################

#use Moo;
use Moose;
use DateTime;

extends 'DataManager';

my $this_version = 0.200102;
my $publish_date = '2014.12.11';
my $App_LocalTZ = DateTime::TimeZone->new( name => 'local' );

has 'this_version' => (isa => 'Num', is => 'ro', default => 0.200102 );


has 'DATA_STORING_SETTINGS' => (isa => 'HashRef', is => 'rw', lazy=> 1, reader => 'get_data_storing_conf', builder => '__load_data_storing_settings' );

## builder methods
sub __load_local_data_storing_settings { ## not used...yet
	my $self = shift;
	my $_pmgr = $self->_processManager();
}
sub __load_data_storing_settings {
	my $self = shift;
	my $_pmgr = $self->_processManager();
	my $me = 'dMGR - LOAD SETTINGS BUILD';
	if(!$_pmgr) {
		warn "[$me] failed to find process mgr object...cannot set signals!\n";
		die "\tdying to fix...\n";
		return undef;
	}
	my $carp = 1;
	my $map = {};
	my $dataforms = $self->{MAKE_DATA_OPTIONS};
	my $database = $self->{MAKE_DB_OPTIONS};
	my $sd = $_pmgr->data_manager_structure_WxPoeServer();
	my $df = $sd->{data_form};
	my $db = $sd->{database};
	my $ds = $sd->{data_storing};
	my $dt = $sd->{data_typology};
	print "[$me] data mgr config, top-level key count[".scalar(keys %$sd)."] data form configs available[".scalar(keys %$df)."]\n" if $carp;
	foreach my $dkey (keys %$df) {
		$dataforms->{$dkey} = $df->{$dkey};
		print "[$me] data handling config, dkey[$dkey] key ct[".scalar(keys %$df)."] dataform configs available[".scalar(keys %$dataforms)."]\n" if $carp;
	}
	foreach my $dkey (keys %$db) {
		$database->{$dkey} = $db->{$dkey};
		print "[$me] databasing config, dkey[$dkey] key ct[".scalar(keys %$db)."] databasing configs available[".scalar(keys %$database)."]\n" if $carp;
	}
	foreach my $dkey (keys %$ds) {
		$map->{$dkey} = $ds->{$dkey};
		print "[$me] data storing config, dkey[$dkey] key ct[".scalar(keys %$ds)."] datastoring configs available[".scalar(keys %$map)."]\n" if $carp;
	}
	foreach my $dkey (keys %$dt) {
		$map->{$dkey} = $dt->{$dkey};
		print "[$me] data typology config, dkey[$dkey] key ct[".scalar(keys %$dt)."] datastoring configs available[".scalar(keys %$map)."]\n" if $carp;
	}
	return $map;
}

## configuration methods
sub load_prev_data { ## do not use...
	my $self = shift;
	my $_smgr = $self->state_manager();
	my $load = $_smgr->reload_prev_data();
	if(@_) {
		$load = shift;
	}
	if($load) {
		my $_pmgr = $self->_processManager();
		my $file = $_pmgr->_ts_quick_data_store_file();
		print "Quick data file to load: using this file[$file]\n" if $self->{TESTING_CARP};
		my $key1 = 'DATA_QUICK_KEYS_PREFIX';
		my $key2 = 'DATA_QUICK_KEYS_SUFFIX_BY_PREFFIX_KEY';
		my $key3 = 'QUICK_DATA_KEYS';
		my $key4 = 'PREFFIX_TO_QUICK_DATA_KEYS';
	
#		if(open(my $fh, '<', $file)) {
			print "=[prev data config]= Crushing ts_data_container with stored ts data values\n";
			#my $yml = LoadFile $file;
			my $yml = $_pmgr->ts_load_file($file);
			
			if(exists $yml->{quickdata}) {
				my $qyml = $yml->{quickdata};
				if(exists $qyml->{$key1}) {
					$self->{$key1} = $qyml->{$key1};
				}
				if(exists $qyml->{$key2}) {
					$self->{$key2} = $qyml->{$key2};
				}
				if(exists $qyml->{$key3}) {
					$self->{$key3} = $qyml->{$key3};
				}
				if(exists $qyml->{$key4}) {
					$self->{$key4} = $qyml->{$key4};
				}
			}

#		} else {
#			print "== Info: no [ts_data_store.yml] file exists\n";
#		}
	}
	return 1;
}
sub save_quick_data {
	my $self = shift;
	#my $key1 = 'DATA_QUICK_KEYS_PREFIX';
	my $key1 = 'QUICK_DATA_G3KEYED_PRE';
	my $key2 = 'DATA_QUICK_KEYS_SUFFIX_BY_PREFFIX_KEY';
	#my $key3 = 'QUICK_DATA_KEYS';
	my $key3 = 'QUICK_DATA_G3KEYED';
	my $key3a = 'QUICK_DATA_KEYS';
	my $key4 = 'DATA_KEYS_INTEGRATE';
	my $key5 = 'QUICK_DATA_BIG_KEYS';
	my $key6 = 'LEADER_DATA_BY_SORT_KEY';
	my $key7 = 'GENDER_LEADER_DATA_BY_SORT_KEY';
	my $key8 = 'AGEGRP_LEADER_DATA_BY_SORT_KEY';
	my $key9 = 'INDEX_VALUE_BY_SP_BY_MNUM';
	my $key10 = 'RAW_DATA_KEYS_DMGR_HITS';
	my $key11 = 'LAP_TIME_DATA_BY_INDEX_CNUM';
	my $key12 = 'TRACKING_KEYS_INPUT_FILTER';
	my $key12a = 'SORTABLE_DATA_BY_SCPKEY_MNUM_SECS';
	
	my $outyml = {};
	if(!exists $self->{$key1}) {
		print "Warning! key1[$key1] appears to be an invalid hash[".$self->{$key1}."]\n\n";
	} elsif(!$self->{$key1}) {
		print "ERROR! key1[$key1] appears to be an invalid hash...perhaps a bad import of previous data!\n\n";
	} else {
		if(scalar(keys $self->{$key1})) {
			$outyml->{$key1} = $self->{$key1};
		}
	}
	if(scalar(keys $self->{$key2})) {
		$outyml->{$key2} = $self->{$key2};
	}
	if(scalar(keys $self->{$key3})) {
		$outyml->{$key3} = $self->{$key3};
	}
	if(scalar(keys $self->{$key3a})) {
		$outyml->{$key3a} = $self->{$key3a};
	}
	if(scalar(keys $self->{$key4})) {
		$outyml->{$key4} = $self->{$key4};
	}
	if(scalar(keys $self->{$key5})) {
		$outyml->{$key5} = $self->{$key5};
	}
	if(scalar(keys $self->{$key6})) {
		$outyml->{$key6} = $self->{$key6};
	}
	if(scalar(keys $self->{$key7})) {
		$outyml->{$key7} = $self->{$key7};
	}
	if(scalar(keys $self->{$key8})) {
		$outyml->{$key8} = $self->{$key8};
	}
	if(scalar(keys $self->{$key9})) {
		$outyml->{$key9} = $self->{$key9};
	}
	if(scalar(keys $self->{$key10})) {
		$outyml->{$key10} = $self->{$key10};
	}
	if(scalar(keys $self->{$key11})) {
		$outyml->{$key11} = $self->{$key11};
	}
	if(scalar(keys $self->{$key12})) {
		$outyml->{$key12} = $self->{$key12};
	}
	if(scalar(keys $self->{$key12a})) {
		$outyml->{$key12a} = $self->{$key12a};
	}
	my $_pmgr = $self->_processManager();
#	my $_pmgr = $self->_processManager();
	my $file = $_pmgr->_ts_quick_data_store_file();
	print "Saving [".scalar(keys %$outyml)."] keys of quick data file [$file]\n" if $self->{TESTING_CARP};
	$_pmgr->pipe_datadump_yml($file, $outyml);

	return 1;
}
sub save_dmgr_state {
	my $self = shift;
	my $key1 = 'DATA_KEYS_INTEGRATE_BY_SP_ARPID';
	my $key2 = 'SP_RW_OPEN_SECS_LATEST_BY_CODEDNUM';
	my $key3 = 'DATA_KEYS_ALL_RECEIVED_BY_SP_ARPID';
	my $key4 = 'SP_RW_SIZE_SECS';
	my $key5 = 'SP_RW_OPEN_SECS_PREVIOUS_BY_CODEDNUM';
	my $key6 = 'DATA_KEYS_INTEGRATE_MAPPED_TO_BIG_KEYS';
	my $key7 = 'INDEX_VALUE_BY_SP_BY_MNUM';
	my $key8 = 'COURSE_SP_RW_SIZE_SECS';
	my $key10 = 'CLIENT_SP_RW_OPEN_SECS_LATEST_BY_CODEDNUM';
	my $key11 = 'CLIENT_SP_RW_OPEN_SECS_PREVIOUS_BY_CODEDNUM';
	my $key12 = 'JS_INDEX_VALUE_BY_SP_BY_MNUM';
	my $key13 = 'JS_SP_RW_OPEN_SECS_LATEST_BY_CODEDNUM';
	my $key14 = 'JS_SP_RW_OPEN_SECS_PREVIOUS_BY_CODEDNUM';
	my $key101 = 'USE_GEN3_KEY';
#	my $key102 = 'USE_KEY_SUFFIX';
	my $outyml = {};
	if(scalar(keys $self->{$key1})) {
		$outyml->{$key1} = $self->{$key1};
	}
	$outyml->{$key2} = $self->{$key2};
	if(scalar(keys $self->{$key3})) {
		$outyml->{$key3} = $self->{$key3};
	}
	$outyml->{$key4} = $self->{$key4};
	if(scalar(keys $self->{$key5})) {
		$outyml->{$key5} = $self->{$key5};
	}
	if(scalar(keys $self->{$key6})) {
		$outyml->{$key6} = $self->{$key6};
	}
	if(scalar(keys $self->{$key7})) {
		$outyml->{$key7} = $self->{$key7};
	}
	if(scalar(keys $self->{$key8})) {
		$outyml->{$key8} = $self->{$key8};
	}
	if(scalar(keys $self->{$key10})) {
		$outyml->{$key10} = $self->{$key10};
	}
	if(scalar(keys $self->{$key11})) {
		$outyml->{$key11} = $self->{$key11};
	}
	if(scalar(keys $self->{$key12})) {
		$outyml->{$key12} = $self->{$key12};
	}
	if(scalar(keys $self->{$key13})) {
		$outyml->{$key13} = $self->{$key13};
	}
	if(scalar(keys $self->{$key14})) {
		$outyml->{$key14} = $self->{$key14};
	}
	if(exists $self->{$key101}) {
		$outyml->{$key101} = $self->{$key101};
	}
	my $_pmgr = $self->_processManager();
	my $file = $_pmgr->_ts_dmgr_state_store_file();
	print "Saving [".scalar(keys %$outyml)."] keys of dmgr state data file [$file]\n" if $self->{TESTING_CARP};
	$_pmgr->pipe_datadump_yml($file, $outyml);

	return 1;
}
sub save_Mdata {
	my $self = shift;
	my $key1 = 'MONITOR_DATA_BY_MNUMBER';
	my $outyml = {};
	if(scalar(keys $self->{$key1})) {
		$outyml->{$key1} = $self->{$key1};
	}
	my $_pmgr = $self->_processManager();
	my $file = $_pmgr->_ts_dmgr_Mdata_store_file();
	print "Saving [".scalar(keys %$outyml)."] keys of dmgr Mdata file [$file]\n" if $self->{TESTING_CARP};
	$_pmgr->pipe_datadump_yml($file, $outyml);

	return 1;
}
sub load_existing_quick_data {
	my $self = shift;
	if($self->{QUICK_DATA_DMGR_RELOADED}) {
		## this has already been done...do not overwrite!
		return 1;
	}
	#my $key1 = 'DATA_QUICK_KEYS_PREFIX';
	my $key1 = 'QUICK_DATA_G3KEYED_PRE';
	my $key2 = 'DATA_QUICK_KEYS_SUFFIX_BY_PREFFIX_KEY';
	#my $key3 = 'QUICK_DATA_KEYS';
	my $key3 = 'QUICK_DATA_G3KEYED';
	my $key3a = 'QUICK_DATA_KEYS';
	my $key4 = 'DATA_KEYS_INTEGRATE';
#	my $key4 = 'PREFFIX_TO_QUICK_DATA_KEYS';
	my $key5 = 'QUICK_DATA_BIG_KEYS';
	my $key6 = 'LEADER_DATA_BY_SORT_KEY';
	my $key7 = 'GENDER_LEADER_DATA_BY_SORT_KEY';
	my $key8 = 'AGEGRP_LEADER_DATA_BY_SORT_KEY';
	my $key9 = 'INDEX_VALUE_BY_SP_BY_MNUM';
	my $key10 = 'RAW_DATA_KEYS_DMGR_HITS';
	my $key11 = 'LAP_TIME_DATA_BY_INDEX_CNUM';
	my $key12 = 'TRACKING_KEYS_INPUT_FILTER';
	my $key12a = 'SORTABLE_DATA_BY_SCPKEY_MNUM_SECS';
	my $_pmgr = $self->_processManager();
	my $file = $_pmgr->_ts_quick_data_store_file();
	print "Quick data file to load: using this file[$file]\n" if $self->{TESTING_CARP};
	print "=[prev Quick data config]= Crushing quick data containers with stored ts data values\n";
	my $yml = $_pmgr->ts_load_file($file);
	if(exists $yml->{$key1}) {
		my $v1 = $yml->{$key1};
		if($v1=~/HASH/i) {
			$self->{$key1} = $yml->{$key1};
		}
	}
	if(exists $yml->{$key2}) {
		my $v2 = $yml->{$key2};
		if($v2=~/HASH/i) {
			$self->{$key2} = $yml->{$key2};
		}
	}
	if(exists $yml->{$key3}) {
		my $v3 = $yml->{$key3};
		if($v3=~/HASH/i) {
			$self->{$key3} = $yml->{$key3};
		}
	}
	if(exists $yml->{$key3a}) {
		my $v3 = $yml->{$key3a};
		if($v3=~/HASH/i) {
			$self->{$key3a} = $yml->{$key3a};
		}
	}
	if(exists $yml->{$key4}) {
		my $v4 = $yml->{$key4};
		if($v4=~/HASH/i) {
			$self->{$key4} = $yml->{$key4};
		}
	}
	if(exists $yml->{$key5}) {
		my $v5 = $yml->{$key5};
		if($v5=~/HASH/i) {
			$self->{$key5} = $yml->{$key5};
		}
	}
	if(exists $yml->{$key6}) {
		my $v6 = $yml->{$key6};
		if($v6=~/HASH/i) {
			$self->{$key6} = $yml->{$key6};
		}
	}
	if(exists $yml->{$key7}) {
		my $v7 = $yml->{$key7};
		if($v7=~/HASH/i) {
			$self->{$key7} = $yml->{$key7};
		}
	}
	if(exists $yml->{$key8}) {
		my $v8 = $yml->{$key8};
		if($v8=~/HASH/i) {
			$self->{$key8} = $yml->{$key8};
		}
	}
	if(exists $yml->{$key9}) {
		my $v = $yml->{$key9};
		if($v=~/HASH/i) {
			$self->{$key9} = $yml->{$key9};
		}
	}
	if(exists $yml->{$key10}) {
		my $v = $yml->{$key10};
		if($v=~/HASH/i) {
			$self->{$key10} = $yml->{$key10};
		}
	}
	if(exists $yml->{$key11}) {
		my $v = $yml->{$key11};
		if($v=~/HASH/i) {
			$self->{$key11} = $yml->{$key11};
		}
	}
	if(exists $yml->{$key12}) {
		my $v = $yml->{$key12};
		if($v=~/HASH/i) {
			$self->{$key12} = $yml->{$key12};
		}
	}
	if(exists $yml->{$key12a}) {
		my $v = $yml->{$key12a};
		if($v=~/HASH/i) {
			$self->{$key12a} = $yml->{$key12a};
		}
	}

	$self->{QUICK_DATA_DMGR_RELOADED} = 1;
	return 1;
}


no Moose; # keywords are removed from the TSCourse package

1;  # so the require or use succeeds