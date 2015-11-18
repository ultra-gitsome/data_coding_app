package YmlCodingServer;
#######################################
#
#   This package creates a YAML (for data coding) WXPoeServer object 
#   Listener provides [nodal-type] data to client connections
#   DATA service type is set via method imports from service script
#
#######################################

use Moose;
use POE;
use POE::Filter::Reference;

extends 'WxPoeServer';

#use Timing::WxPoeServer::Clients::PushClient;
#use Timing::WxPoeServer::Clients::ReaderClient;

## set a local (shared) 'state' variable for indexing new instances....Moose does not seem to handle this..
my $alias_index = 0;

has 'publish_date' => (isa => 'Str', is => 'ro', builder => '__set_publishdate' );
has 'SERVER_DATA_TYPE' => (isa => 'Str', is => 'ro', builder => '__set_server_data_type' );
has 'SERVER_DATA_TYPE_PROPER' => (isa => 'Str', is => 'ro', builder => '__set_server_data_Type' );
has 'JSON_EXPORT_METHOD' => (isa => 'Str', is => 'ro', builder => '__set_json_method' );
has 'SERVER_CLIENT_MAIN_QUERY' => (isa => 'Str', is => 'ro', builder => '__set_srvrclnt_query' );
has 'DATA_FETCH_METHOD' => (isa => 'Str', is => 'ro', builder => '__set_data_fetch_method' );
has 'FETCH_DATA_CARP' => (isa => 'Int', is => 'rw', default => 1 );


## builder methods
sub __set_version {
	return 0.006005;
}
sub __set_server_data_Type {
	return 'Collector';
}
sub __set_server_data_type {
	return 'collector';
}
sub __set_publishdate {
	return '2013.05.02';
}
sub __set_json_method {
	return 'export_courses_json';
}
sub __set_srvrclnt_query {
	return 'tellmecourses';
}
sub __set_data_fetch_method {
	return 'set_course_object_data';
}

## admin methods
sub show_version {
	my $self = shift;
	print "[SHOW SERVER VERSION] This server version is: [".$self->{this_version}." - ".$self->{publish_date}."]\n";
	return $self->{ALIAS};
}
sub data_service_Type {
	my $self = shift;
	if(@_) {
		$self->{SERVER_DATA_TYPE_PROPER} = shift;
	}
	return $self->{SERVER_DATA_TYPE_PROPER};
}
sub state_mgr {
	my $self = shift;
	my $_smgr = shift;
	if(defined $_smgr) { $self->{STATE_MGR_OBJECT} = $_smgr; }
	return $self->{STATE_MGR_OBJECT};
}
sub set_json_export_method {
	my $self = shift;
	if(@_) {
		$self->{JSON_EXPORT_METHOD} = shift;
	}
	return $self->{JSON_EXPORT_METHOD};
}
sub set_data_fetch_method {
	my $self = shift;
	if(@_) {
		$self->{DATA_FETCH_METHOD} = shift;
	}
	return $self->{DATA_FETCH_METHOD};
}
## main query is used in the base _srvr_rcvd_input method
sub set_server_client_main_query {
	my $self = shift;
	if(@_) {
		$self->{SERVER_CLIENT_MAIN_QUERY} = shift;
	}
	return $self->{SERVER_CLIENT_MAIN_QUERY};
}


sub fetch_n_set_data {
	my $self = shift;
	my $_smgr = $self->{STATE_MGR_OBJECT};
	my $_dbh = shift;
	if($_dbh) {
		####
		## the $data_fetch_method_name stores a set of nodal-typed (course/runner/tag) objects/hashkeys into the state manager (stored there).
		####
		my $data_fetch_method_name = $self->{DATA_FETCH_METHOD};
		if(!$_smgr->$data_fetch_method_name($_dbh)) {
			print "\nERROR! Problem loading data within [$data_fetch_method_name]\n\n";
			return undef;
		}
	}
	return 1;
}
sub set_data {
	my $self = shift;
	my $carp = 0;
	my $_smgr = $self->{STATE_MGR_OBJECT};
	
	####
	## no checks ...
	####
	my $data_packet = {};
	$data_packet->{data} = undef;
	$data_packet->{error} = 'No data';
	$data_packet->{status} = 0;
	my $json_export_method = $self->{JSON_EXPORT_METHOD};
	my $newdata = $_smgr->$json_export_method();
	my $size = 0;
	if(exists $newdata->{data}) {
		$data_packet->{data} = $newdata->{data};
		$size = scalar(keys %$data_packet);
		if($size) { delete $data_packet->{error}; }
	}
	my $e = undef;
	if(exists $newdata->{error}) {
		$data_packet->{error} = $newdata->{error};
		$carp = 1;
	}

	print "[".$self->{'SERVER_DATA_TYPE'}."] fetched data, count[$size] \n" if $self->{FETCH_DATA_CARP};
	print "\tBUT with errors [".$newdata->{error}."]\n" if $carp;

	return $data_packet;
}
sub update_server_data {
	my $self = shift;
	my $_smgr = $self->{STATE_MGR_OBJECT};
	my $_dbh = shift;
	if(!$_dbh) {
		print "No DBH!! Cannot reload [".$self->{SERVER_DATA_TYPE}."] data!!\n\n";
		return undef;
	}
	####
	## reset server_object_data within the state manager
	####
	my $data_fetch_method_name = $self->{DATA_FETCH_METHOD};
	if(!$_smgr->$data_fetch_method_name($_dbh)) {
		warn "\nERROR! Problem loading [".$self->{SERVER_DATA_TYPE}."] data within [$data_fetch_method_name]\n\n";
		return undef;
	}
	return 1;
}

sub make_server_client_conn_NA {
	my ($self,$aliaskey,$sigkey,$sigvalue,$stat_dyn_client_tog, $kernel) = @_;
	my $me = 'MAKE PUSHCLIENT CONN';
	my ($client_address, $client_port) = $self->get_connection_info(sigkey => $sigkey, sigvalue => $sigvalue, dyn_client_toggle => $stat_dyn_client_tog);
	print "[$me - START CONN] creating a data conn object[$aliaskey] for sigkey[$sigkey] on address[$client_address]:[$client_port]\n" if $self->{READY_CHECK_CARP};
#	my $_conn = ClientConn->new( REMOTE_ADDRESS => $client_address, REMOTE_PORT => $client_port );
	my $_conn = PushClient->new( REMOTE_ADDRESS => $client_address, REMOTE_PORT => $client_port );
	my $alias = $_conn->get_alias();
	## map aliases to be consistent with 'by_name' methods
	my $amap = $self->{ALIAS_TO_ALIASKEY_MAP};
	$amap->{$alias} = $aliaskey;
	my $main_alias = $self->get_alias();
	$_conn->main_caller_alias($main_alias);
	$_conn->signal_call($sigkey);
	$_conn->kernel_ptr($kernel);
	$_conn->name_alias_key($aliaskey);
	my $_pmgr = $self->process_mgr();
	$_conn->pmgr_ptr($_pmgr);
	$self->add_client_obj($aliaskey,$_conn);
	print "[$me - START CONN] created data conn [$aliaskey] for sigkey[$sigkey] \n" if $self->{READY_CHECK_CARP};
	return $_conn;
}
sub manage_ready_wait {
	my ($self,$_conn,$kernel,$sigkey,$sigvalue,$wait_ready,$wait_ready_max_count,$trace) = @_;
	my $me = __PACKAGE__ . ' MANAGE READY WAIT';
	if($wait_ready) {
		$self->{WAIT_READY}->{$sigkey} = 1;
		$self->{WAIT_STATE_READY}->{$sigkey}->{done} = 0;
		$self->{WAIT_STATE_READY}->{$sigkey}->{count} = 0;
		$self->{WAIT_STATE_READY}->{$sigkey}->{max_count} = $wait_ready_max_count;
		$self->{WAIT_STATE_READY}->{$sigkey}->{direct_signal} = 1;
		print "{TRACE}[$me] set wait_ready[$wait_ready] max count[$wait_ready_max_count] for sigkey[$sigkey] directsignal[".$self->{WAIT_STATE_READY}->{$sigkey}->{direct_signal}."] -- creating session\n" if $trace;
	}
	
	####
	## this object-set contains both a reader and push client
	## the ready_wait is separated by the READER_CLIENT_FLAG
	####
	print "{TRACE}[$me] NO trigger for session-recreate, if no client (falsy)[] for sigkey[$sigkey]; wait for ready?[$wait_ready]\n" if $trace;
#	if($self->{READER_CLIENT_FLAG}) {
#		$_conn->reader_session_create();
#		$self->{READER_CLIENT_FLAG} = 0;
#	} else {
		$_conn->session_create();
#	}
	if($wait_ready) {
		$kernel->delay(wait_ready => 1, $sigkey, $sigvalue);
	}
	return;
}

sub _datapack_management_RDATA {
	my ($self, $heap, $client, $hub_key, $datapack) = @_[OBJECT, HEAP, ARG0, ARG1, ARG2];
	
	my $_pmgr = $self->{PROCESS_MGR_OBJECT};
	my $_dmgr = $_pmgr->_dataManager();
	my $_wfmgr = $self->{WXFRAME_MGR_OBJECT};

	return;
}
 

## module end
no Moose;
1