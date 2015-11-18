package WxPoeLayoutDataCoder;
#######################################
#
#   This package branches the main functions outside the Frame package (to get outside of the 'new()')
#
#######################################

#use Moose;
use strict;
use warnings;

#use Timing::DataCoding::AppCon::Panels::WxDataCoderMainPanel;
BEGIN { 
	eval { require Timing::DataCoding::AppCon::Panels::WxDataCoderMainPanel }
		or die "Error: Timing::DataCoding::AppCon::Panels::WxDataCoderMainPanel not installed: $@";
   import Timing::DataCoding::AppCon::Panels::WxDataCoderMainPanel;
}
#use Timing::DataCoding::AppCon::Panels::TSReader1Panel;
BEGIN { 
	eval { require Timing::DataCoding::AppCon::Panels::TSReader1Panel }
		or die "Error: Timing::DataCoding::AppCon::Panels::TSReader1Panel not installed: $@";
   import Timing::DataCoding::AppCon::Panels::TSReader1Panel;
}
#use Timing::DataCoding::AppCon::Panels::WxDataCoderAspectPanel;
BEGIN { 
	eval { require Timing::DataCoding::AppCon::Panels::WxDataCoderAspectPanel }
		or die "Error: Timing::DataCoding::AppCon::Panels::WxDataCoderAspectPanel not installed: $@";
	import Timing::DataCoding::AppCon::Panels::WxDataCoderAspectPanel;
}
#use Timing::DataCoding::AppCon::Panels::WxDataCoderGridPanel;
BEGIN { 
	eval { require Timing::DataCoding::AppCon::Panels::WxDataCoderGridPanel }
		or die "Error: Timing::DataCoding::AppCon::Panels::WxDataCoderGridPanel not installed: $@";
   import Timing::DataCoding::AppCon::Panels::WxDataCoderGridPanel;
}
#use Timing::DataCoding::AppCon::Panels::WxDataCoderCodesPanel;
BEGIN { 
	eval { require Timing::DataCoding::AppCon::Panels::WxDataCoderCodesPanel }
		or die "Error: Timing::DataCoding::AppCon::Panels::WxDataCoderCodesPanel not installed: $@";
	import Timing::DataCoding::AppCon::Panels::WxDataCoderCodesPanel;
}
#use Timing::DataCoding::AppCon::Panels::WxDataCoderSpecialPanel;
BEGIN { 
	eval { require Timing::DataCoding::AppCon::Panels::WxDataCoderSpecialPanel }
		or die "Error: Timing::DataCoding::AppCon::Panels::WxDataCoderSpecialPanel not installed: $@";
	import Timing::DataCoding::AppCon::Panels::WxDataCoderSpecialPanel;
}
#use Timing::DataCoding::AppCon::Panels::WxVStatusPanel;
BEGIN { 
	eval { require Timing::DataCoding::AppCon::Panels::WxVStatusPanel }
		or die "Error: Timing::DataCoding::AppCon::Panels::WxVStatusPanel not installed: $@";
	import Timing::DataCoding::AppCon::Panels::WxVStatusPanel;
}


use vars qw(@ISA);
@ISA = qw(Wx::Frame);

use vars qw(@ISA);

use Wx::Grid;
@ISA = qw(Wx::Grid);
use Wx qw(:everything);

use Wx::DemoModules::wxGridCER;

#use Wx::Event qw(:everything);
use Wx::Event qw(EVT_SIZE
                 EVT_MENU
                 EVT_IDLE
                 EVT_COMBOBOX
                 EVT_UPDATE_UI
                 EVT_TOOL_ENTER
				 EVT_BUTTON
				 EVT_LEFT_DCLICK
				 EVT_RIGHT_DOWN
				 EVT_CLOSE
				 EVT_TEXT_ENTER
				 EVT_KILL_FOCUS
				 EVT_SET_FOCUS
);
####
## NOTE!!!
## this must be placed after all the Wx 'use' statements...no idea why....
####
#use Timing::WxDisplay::LayoutMain;
BEGIN { 
	eval { require Timing::WxDisplay::LayoutMain }
		or die "Error: Timing::WxDisplay::LayoutMain not installed: $@";
   import Timing::WxDisplay::LayoutMain;
}

#extends 'LayoutMain';
@ISA = qw(LayoutMain); ## inherits from Main WxPoeApp

## set a local (shared) 'state' variable for indexing new instances....Moose does not seem to handle this..
my $trace_all = 1;
my $alias_index = 0;
my $init_display_carp = 1;
my $_grid_index_value_offset = 1;
my $_screen_input_client_name = 'Monitor';
my $_calculate_lap_averages = 1;
my $_forecast_next_lap_time = 0;
my $_reader_clients = {reader1_go => 'reader_1',reader2_go => 'reader_2'};
my $_push_data_fwd = 1;
my $_push_client_name = 'push';
my $_push_notice_wxframe_method = 'push_notice_to_forward_data'; ## must be present in TSRMonitorAppCon


sub _display_settings {
	my $self = shift;
	if(@_) { $self->{DISPLAY_SETTINGS} = shift; }
	return $self->{DISPLAY_SETTINGS};
}
sub global_display_settings {
	my $self = shift;
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	my $_smgr = $_pmgr->state_manager();

	
	return 1;
}
sub reload_actions {
	my ($self,$trace) = @_;
	if($trace_all) { $trace = 1; }
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $frameident = $wxframe->getFrameIdent();
	$self->load_mdata_columns($trace);
	$self->load_selectable_codes($trace);
	$_wfmgr->load_textbox_data_this_wxframe($wxframe,$trace); #load_sidebar_log($wxframe);
	return 1;
}
sub pulse_display_update {
	my $self = shift;
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $trace = 0;

	if($self->{TIMER_ON}) {

		## hardcoded field names...
		my $panel = 'mainpanel';
		my $field = 'time_diff';
		print "[".__PACKAGE__." - PULSE UPDATE] to panel[$panel] field[$field] \n" if $trace;

		my $on_off = 1;
		## (-1) switches timer off
		if($self->{TIMER_ON}==-1) {
			## falsy is 'off'
			$on_off = 0;
#			$hms = "-:-:-";
			$self->{TIMER_ON} = 0;
		}
		my $hms = $_wfmgr->hms_delta_from_timer_start($field,$on_off,$trace);
		if(!exists $wxframe->{$panel}->{$field}) {
	#		print "[$me] field[$field] in panel[$panel] does not exist!\n";
			return undef;
		}
		if(!$hms) {
			print "[".__PACKAGE__." - PULSE UPDATE] timer return value is null for field[$field] \n";
			die "dying to fix...[PULSE UPDATE]\n";
			return undef;
		}
			
		$hms = "Timer ".$hms;
		$wxframe->{$panel}->{$field}->SetLabel($hms);
	}
	
	return 1;
} 
sub save_group {
	my ($self,$wxframe,$trace) = @_;
	my $me = __PACKAGE__ . ' SAVE DATA GROUPS';
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	print "[$me] sending to *save_all_state_data_stacks* in wfMGR\n" if $trace;
	$_wfmgr->save_all_state_data_stacks($wxframe,$trace);

	$_dmgr->save_yaml_file_data($trace);

	return 1;
}

sub process_init_methods {
	my $self = shift;
	my $wxframe = $self->wxframe_handle();
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();

	my $me = 'PROCESS INIT METHODS';
	my (%pms) = @_;
	if(!exists $pms{panel}) {
		print "[PROCESS INIT METH] ERROR! panel value is missing!  in[".__PACKAGE__."] at line[".__LINE__."]\n";
		die "\tdying to fix [PROCESS INIT METH] error...\n\n";
		return undef;
	}
	my $panel = $pms{panel};
	if(!exists $pms{field}) {
		print "[PROCESS INIT METH] ERROR! field value is missing on panel [$panel] in[".__PACKAGE__."] at line[".__LINE__."]\n";
		die "\tdying to fix [PROCESS INIT METH] error...\n\n";
		return undef;
	}
	my $field = $pms{field};
	if(!exists $pms{datakey}) {
		print "[PROCESS INIT METH] ERROR! data key value is missing on panel [$panel] field[$field] in[".__PACKAGE__."] at line[".__LINE__."]\n";
		die "\tdying to fix [PROCESS INIT METH] error...\n\n";
		return undef;
	}
	my $key_to_data = $pms{datakey};
	my $method = '_default_';
	if(exists $pms{method} and $pms{method}) {
		$method = $pms{method};
	}

	if($key_to_data=~/wfmgr/i) {
		if($method=~/hms_delta_from_main_display_time/i) {
			my $hms = $_wfmgr->hms_delta_from_main_display_time();
			if(!exists $wxframe->{$panel}->{$field}) {
				print "[$me] field[$field] in panel[$panel] does not exist!\n";
				return undef;
			}
			$hms = "Timer ".$hms;
			$wxframe->{$panel}->{$field}->SetLabel($hms);
		}
		if($method=~/main_display_start_time/i) {
			my $dtg = $_wfmgr->main_display_start_time();
			if(!exists $wxframe->{$panel}->{$field}) {
				print "[$me] field[$field] in panel[$panel] does not exist!\n";
				return undef;
			}
			$dtg = "Start: ".$dtg;
			$wxframe->{$panel}->{$field}->SetLabel($dtg);
		}
		return 1;
	}
	
	return 1;
}
sub set_event_link { ## may not be needed...
	my $self = shift;
	my $wxframe = $self->{WXFRAME_PTR};
	my $type = $_[0];
	my $cname = $_[1];
	my $subname = $_[2];
	print "[SET EVENT LINK} setter!! [self] [".$self."] winframe[$wxframe] cname [".$_[0]."]set link[".$_[1]."]\n";
	if($type=~/button/i) {
		if(!$subname) {
			$subname = $self->{DEFAULT_EVENT_METHOD};
		}
		print "[EVENT SETUP - BUTTON] wxpoe configuration [$cname] sub[$subname] \n";
		if(!defined $cname or !defined $subname) {
			warn "[EVENT SETUP] wxpoe configuration error. missing name [$cname] or method [$subname]. Signal to button mapping bad!\n";
			return undef;
		}
		EVT_BUTTON $wxframe,$wxframe->{$cname},\&$subname;

	}
	return 1;
}
sub grid_display_index_offset {
	my $self = shift;
	my $wxframe = $self->{WXFRAME_PTR};
	if(!defined $wxframe) {
		warn "[GR?D DISP INDEX] missing wxframe!\n";
		die "\tdying to fix........\n";
		return undef;
	}
	my $_wfmgr = $self->wxframe_mgr_ptr();
	$_wfmgr->grid_main_display_index_offset($_grid_index_value_offset);
	return $_grid_index_value_offset;
}

## updating needed...to retrieve data manager
sub on_click_submit {
	my $layout_ptr = undef;
	my $wxframe = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' ON CLICK SUBMIT';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$wxframe,$event) = @_;
	} else {
		($wxframe,$event) = @_;
	}
	if(!defined $wxframe) {
		warn "[$me] ERROR the wxframe object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	my $_pmgr = $main_app->getProcessMgr();
	my $_dmgr = $_pmgr->data_manager();
	my $_smgr = $_pmgr->state_manager();
	my $client = $_screen_input_client_name;
	my $carp = 1;
	my $trace = 1;
	my $inputfield_deduct = 20;

	print "  clicked event[$event] in winframe[$wxframe]\n" if $trace;
	my $t = $event->GetEventType();
	print "  clicked event, obj[".$event->GetEventObject()."] type[$t]\n" if $trace;
	my $mainkey = undef;

	if($event->GetEventType() == 10084 or $event->GetEventType() == 10008) {
		my $eobj = $event->GetEventObject();
		my $this_id = $eobj->GetId();
		print "  clicked event, useful button type...id[".$this_id."] label[".$eobj->GetLabel."]\n" if $trace;

		my $prev_btn_id = 501;
		my $next_btn_id = 502;
		my $confirm_btn_id = 503;
		
		my $topkey = "data_coding";
		my $stuff = $_wfmgr->gui_ref_ids_panel_n_ctrls($this_id);
		print "[$me]  id-ed stuff, panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;

		if($this_id==$prev_btn_id or $this_id==$next_btn_id) {
			my @keys = $layout_ptr->set_new_sentence($stuff->{cname},$stuff->{panel},undef,$trace);
			if(scalar(@keys)) {
				if(defined $keys[0] and $keys[0]=~/^t(\d+)s(\d+)/i) {
					my $meth = 'gui_wxapp_ctrls_sync5';
					my $s5 = $_wfmgr->$meth(key => $stuff->{cname},trace => $trace);
					if(!exists $wxframe->{$stuff->{panel}}->{$s5->{link}->{pull}}) {
						print "[$me] wxframe push cntrl[".$s5->{link}->{pull}."] does not exist in panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
						return undef;
					}
					my $srcbox = $wxframe->{$stuff->{panel}}->{$s5->{link}->{pull}};
					my $srcbox_ct = $srcbox->GetCount();
					$layout_ptr->clear_data_fields($mainkey,$trace);
					$layout_ptr->populate_data_fields($mainkey,$1,$2,$srcbox_ct,$trace);
					$layout_ptr->populate_special_fields($mainkey,$1,$2,$trace);
					print "[$me] sentence change done, cname[".$stuff->{cname}."] panel[".$stuff->{panel}."] mainkey[".$keys[0]."] skey[".$keys[1]."]\n" if $trace;
#					return 1;
				}
			}
			if($this_id==$prev_btn_id) {

				my $meth = 'gui_wxapp_ctrls_sync5';
				my $s5 = $_wfmgr->$meth(key => $stuff->{cname},trace => $trace);
				if(!exists $wxframe->{$stuff->{panel}}->{$s5->{link}->{pull}}) {
					print "[$me] wxframe push cntrl[".$s5->{link}->{pull}."] does not exist in panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
					return undef;
				}
				my $srcbox = $wxframe->{$stuff->{panel}}->{$s5->{link}->{pull}};
				my $srcbox_index = $srcbox->GetCurrentSelection();
				## increment src index
				if($srcbox_index>0) {
					$srcbox_index--;
				}
				my $ct = $srcbox->GetCount();
				print "[$me] getting sentence ct[$ct] new index[$srcbox_index]for [".$stuff->{cname}."] on panel[".$stuff->{panel}."] topkey[$topkey]\n" if $trace;
				$srcbox->SetSelection($srcbox_index);

			}
			if($this_id==$next_btn_id) {

				my $meth = 'gui_wxapp_ctrls_sync5';
				my $s5 = $_wfmgr->$meth(key => $stuff->{cname},trace => $trace);
				if(!exists $wxframe->{$stuff->{panel}}->{$s5->{link}->{pull}}) {
					print "[$me] wxframe push cntrl[".$s5->{link}->{pull}."] does not exist in panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
					return undef;
				}
				my $srcbox = $wxframe->{$stuff->{panel}}->{$s5->{link}->{pull}};
				my $srcbox_index = $srcbox->GetCurrentSelection();
				## increment src index
				my $ct = $srcbox->GetCount() - 1;
				if($srcbox_index<$ct) {
					$srcbox_index++;
				#	$srcbox_index--;
				}
				print "[$me] getting sentence ct[$ct] new index[$srcbox_index] for [".$stuff->{cname}."] on panel[".$stuff->{panel}."] topkey[$topkey]\n" if $trace;
				$srcbox->SetSelection($srcbox_index);

			}
		}
		if($this_id==$confirm_btn_id) {

			my $skey = undef;
			if(!$mainkey) {
				my $keys = $_dmgr->top_key_primary_keys(topkey => $topkey, trace => $trace);
				$mainkey = $keys->{primary_key_1};
				$skey = $keys->{primary_key_2};
			}
			if(!defined $mainkey) {
				print "[$me] WARNING! mainkey not set. Presuming premature clicking of sentence navigator buttons [".$eobj->GetLabel."] cname[".$stuff->{cname}."]\n\n";
#				die "\tdying to fix [$me]\n";
				return undef;
			}
			$layout_ptr->complete_confirm($topkey,$trace);
			print "[$me] confirmed and stored current sentence[$skey] data, for [".$stuff->{cname}."] on panel[".$stuff->{panel}."] topkey[$topkey]\n" if $trace;

		}
		return;
		
	}
	return 1;
}
sub text_entry_event {
	my $layout_ptr = undef;
	my $wxframe = undef;
	my $event = undef;
	my $me = 'TEXT ENTRY EVENT';
#	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$wxframe,$event) = @_;
	} else {
		($wxframe,$event) = @_;
	}
	if(!defined $wxframe) {
		warn "[$me] ERROR the wxframe object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	my $_pmgr = $main_app->getProcessMgr();
	my $_dmgr = $_pmgr->data_manager();
	my $_smgr = $_pmgr->state_manager();
	my $client = $_screen_input_client_name;
	my $carp = 1;
	my $dcarp = 1;
	my $step_carp = 1;
	my $inputfield_deduct = 10;

	print "***[$me]***" if $carp;
	if($layout_ptr) { print "[ $layout_ptr]" if $carp; }
	print "\n" if $carp;

	print "[$me] event[$event] in winframe[$wxframe]\n" if $step_carp;
	my $t = $event->GetEventType();
	print "[$me] event, obj[".$event->GetEventObject()."] type index[$t] (looking for 10045)\n" if $step_carp;

	if($event->GetEventType() == 10045) {
		my $display = $wxframe->_display_handle();
		my $eobj = $event->GetEventObject();
		my $sp = $_wfmgr->get_sp_values;
		my $sp_loc = $_wfmgr->get_locked_sp_values(); #	$self->{SP_VALUE_LOCKED};
		my $tid = $eobj->GetId();
		my $Mnum = $eobj->GetLabel();
		print "[$me] cntrl_id[$tid] input value[$Mnum]\n" if $carp;

		my $t_mnum = $_wfmgr->checkMnumSubmitEntry($Mnum);
		$eobj->SetLabel('');

		my $mess = "Bib entry [$Mnum]";
		my $mess_scrn = undef;
		my $return = 0;
		if(!defined $t_mnum) {
			$mess = "[$me] Bib entry [$Mnum] is not numeric";
			$mess_scrn = "Bib entry [$Mnum] is not numeric";
			$return = 1;
		} elsif(!$t_mnum) {
			$mess = "[$me] Bib entry [$Mnum] is out of range";
			$mess_scrn = "Bib entry [$Mnum] is out of range";
			$return = 1;
		} elsif(!$t_mnum < 0) {
			$mess = "[$me] Bib entry [$Mnum] negative value";
			$mess_scrn = "Bib entry [$Mnum] is negative value";
			$return = 1;
		}
		if($return) {
			## send bad boy note to screen
			print $mess . "\n" if $carp;
#			$_wfmgr->notice_message(2,$mess);
			$_wfmgr->main_status_box_message($wxframe, $mess_scrn);
			return 0;
		}


		my $spval = "11";
		my $sp_is_end = 1;
		## matching in and out fields are 2 or 3 digits with same sequence
		if($tid > 100) {
			$sp_is_end = 0;
			$tid = $tid - 100;
#			$spval = "10";
		}
		my $spindex = 1;
		my $key = $tid - $inputfield_deduct;
		my $sp_index = $_wfmgr->sp_index_value($key);
		if(!defined $sp_index) {
			my $mess = "SCP index values are not keyed for lookup on key[$key]";
			print "\t $mess\n" if $carp;
			$sp_index = $spindex; 
		}
		$spindex = $sp_index;
		if($spindex) {
			## 
			$spval = $spindex . $sp_is_end;
		}

		my $test_client = 'reader_1';
		print "[$me] submitted entry[$Mnum] passed checks...calling ms_make_localtime_point, client[$client] spval[$spval]\n" if $carp;
		my $keyed = undef;
		my $keyed2 = undef;
		my $lt = 1;
		if($sp_is_end) {
			$keyed = $_dmgr->ms_make_localtime_point_g3(client => $client, mnum => $Mnum, spval => $spval, carp => $dcarp);
			$keyed2 = $_dmgr->ms_make_localtime_point_g3(client => $test_client, mnum => $Mnum, spval => $spval, carp => $dcarp, lasttrack => $lt, secondclient => $client);
		} else {
			$keyed = $_dmgr->ms_make_localtime_out_point_g3(
												client => $client,
												mnum => $Mnum,
												spval => $spval,
												carp => $dcarp
												);
		}
		if(!$keyed) {
			if($keyed == 0) {
				## falsy state indicates duplicate time (rw) value
				my $mess = "Bib [$Mnum] is too early!";
				print "$mess keyed[$keyed] \n";
				$_wfmgr->main_status_box_message($wxframe, $mess);
				return 0;
			}
			print "\n[$me] ERROR! Not able to create proper data key!!\n";
			## send bad boy note to screen
			$_wfmgr->vstatus_runtime_display($wxframe, $mess);
			return undef;
		}

		print "[$me] show datakey returned by dMgr [$keyed]\n" if $carp;
		if($keyed=~/^__in_rw__/i) {
			## reject...not outside of readwindow
			my $mess = "Bib entry [$Mnum] is too early! key[$keyed]";
			$_wfmgr->main_status_box_message($wxframe, $mess);
			return 0;
		}

		my ($keydtype, $keystype, $keydpt,$key_index) = split("__",$keyed);
		if($keydpt=~/(\w+)_c(\d+)([scp]+)(\d+)_(\d+)_(\d+)/) {
			if($sp_is_end) {
				$_wfmgr->load_data_pack_monitor(client => $client, wxframe => $wxframe);
			}
			if($sp_is_end) {
				$_wfmgr->load_data_pack_lasttracker(client => $test_client, wxframe => $wxframe);
			}
			
		}
	}
	return 1;
}
sub off_focus_combobox {
	my $layout_ptr = undef;
	my $wxframe = undef;
	my $event = undef;
	my $me = 'OFF FOCUS COMBOBOX';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$wxframe,$event) = @_;
	} else {
		($wxframe,$event) = @_;
	}
	if(!defined $wxframe) {
		warn "[$me] ERROR the wxframe object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
#	my $_pmgr = $main_app->getProcessMgr();
#	my $_wfmgr = $self->wxframe_mgr_ptr();
#	my $_pmgr = $self->process_mgr_ptr();
#	my $_dmgr = $_pmgr->data_manager();
#	my $_smgr = $_pmgr->state_manager();
	my $carp = 1;
	my $trace = 0;
	if($carp) { $trace = 1; }
	my $step_carp = 1;

	print "  clicked event[$event] in winframe[$wxframe]\n" if $step_carp;
	my $t = $event->GetEventType();
	print "  clicked event type[$t]\n" if $step_carp;

	if($event->GetEventType() == 10114) {
		print "  combo box clicked\n" if $step_carp;
		my $eobj = $event->GetEventObject();
		print "  clicked event obj[$eobj]\n";
	
		my $action_chk = $eobj->GetLabel();
		print "[$me]  clicked label[$action_chk] - doing nothing\n" if $carp;
	}
	if($event->GetEventType() == 10096) {
		print "  combo box clicked\n" if $step_carp;
		my $eobj = $event->GetEventObject();
		my $this_id = $eobj->GetId();
		my $action_val = $eobj->GetCurrentSelection();
		print "  clicked event obj[$eobj] ID[$this_id] current sel[$action_val]\n" if $step_carp;

		my $action_chk = $eobj->GetLabel();
		print "[".__PACKAGE__." - $me]  clicked label[$action_chk]\n" if $carp;
		if(defined $layout_ptr) {
#			if($this_id==33) {
#			} else {
				$layout_ptr->populate_topic_list($this_id,$action_chk,$trace);
#			}
		}
	}
	$event->Skip();
	return 1;
}
sub evt_textinput_special {
	my $layout_ptr = undef;
	my $wxframe = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' EVT TEXT SPECIAL';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$wxframe,$event) = @_;
	} else {
		($wxframe,$event) = @_;
	}
	if(!defined $wxframe) {
		warn "[$me] ERROR the wxframe object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();

	my $trace = 1;
#	if($carp) { $trace = 1; }
	my $step_carp = 1;

	print "  clicked event[$event] in wxframe[$wxframe]\n" if $step_carp;
	my $t = $event->GetEventType();
	print "  clicked event type[$t]\n" if $step_carp;

	if($event->GetEventType() == 10045) {
		my $eobj = $event->GetEventObject();
		my $this_id = $eobj->GetId();
		my $val = $eobj->GetLabel();
		print "[$me] cntrl_id[$this_id] input value[$val]\n" if $trace;

		my $stuff = $_wfmgr->gui_ref_ids_panel_n_ctrls($this_id);
		print "[$me]  id-ed stuff, panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
		
		my $ref_cntrls = $_wfmgr->gui_wxapp_ctrls_sync3(key => $stuff->{cname}, trace => $trace);
		print "[$me]  ref cntrls, pull[".$ref_cntrls->{link}->{pull}."] push[".$ref_cntrls->{link}->{push}."]\n" if $trace;

		my $type = $ref_cntrls->{link}->{pull}."_".$ref_cntrls->{link}->{push};
		if(defined $layout_ptr) {
			my $d = {};
			$d->{$ref_cntrls->{link}->{push}} = $val;
			$layout_ptr->store_special_data($type,$d,$trace);
			$layout_ptr->set_re_state_field(0);
		}
#		$eobj->SetLabel('');
	}
	$event->Skip();
	return 1;
}
sub evt_combobox_special {
	my $layout_ptr = undef;
	my $wxframe = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' EVT COMBOBOX SPECIAL';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$wxframe,$event) = @_;
	} else {
		($wxframe,$event) = @_;
	}
	if(!defined $wxframe) {
		warn "[$me] ERROR the wxframe object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();

	my $trace = 1;
#	if($carp) { $trace = 1; }
	my $step_carp = 1;

	print "  clicked event[$event] in wxframe[$wxframe]\n" if $step_carp;
	my $t = $event->GetEventType();
	print "  clicked event type[$t]\n" if $step_carp;

	if($event->GetEventType() == 10114) { ## must be older version of Wx....
		print "  combo box clicked\n" if $step_carp;
		my $eobj = $event->GetEventObject();
		print "  clicked event obj[$eobj]\n";
	
		my $action_chk = $eobj->GetLabel();
		print "[$me]  clicked label[$action_chk] - doing nothing\n" if $trace;
	}
	if($event->GetEventType() == 10096) {
		print "  combo box clicked\n" if $step_carp;
		my $eobj = $event->GetEventObject();
		my $this_id = $eobj->GetId();
		my $action_val = $eobj->GetCurrentSelection();
		print "  clicked event obj[$eobj] ID[$this_id] current sel[$action_val]\n" if $step_carp;

		my $action_chk = $eobj->GetLabel();
		print "[$me]  clicked label[$action_chk]\n" if $trace;

		if(!$action_val) {
			## default selection selected - somehow - ignore
			print "[$me] the default selection [$action_chk] has been chosen...ignoring...\n";
			$event->Skip();
			return undef;
		}
		my $stuff = $_wfmgr->gui_ref_ids_panel_n_ctrls($this_id);
		print "[$me]  id-ed stuff, panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
		
		my $ref_cntrls = $_wfmgr->gui_wxapp_ctrls_sync3(key => $stuff->{cname}, trace => $trace);
		print "[$me]  ref cntrls, pull[".$ref_cntrls->{link}->{pull}."] push[".$ref_cntrls->{link}->{push}."]\n" if $trace;

		my $type = $ref_cntrls->{link}->{pull}."_".$ref_cntrls->{link}->{push};
		if(defined $layout_ptr) {
			my $d = {};
			$d->{$ref_cntrls->{link}->{push}} = $action_chk;
			$layout_ptr->store_special_data($type,$d,$trace);
			$layout_ptr->set_re_state_field(0);
		}
	}
	$event->Skip();
	return 1;
}
sub evt_checkbox_special {
	my $layout_ptr = undef;
	my $wxframe = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' EVT CHECKBOX SPECIAL';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$wxframe,$event) = @_;
	} else {
		($wxframe,$event) = @_;
	}
	if(!defined $wxframe) {
		warn "[$me] ERROR the wxframe object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();

	my $trace = 1;
	my $step_carp = 1;

	print "  clicked event[$event] in winframe[$wxframe]\n" if $step_carp;
	my $t = $event->GetEventType();
	print "  clicked event type[$t]\n" if $step_carp;

	if($event->GetEventType() == 10085) {
		print "  checkbox clicked\n" if $step_carp;
		my $eobj = $event->GetEventObject();
		my $this_id = $eobj->GetId();
		my $action_val = $eobj->GetValue();
		my $is_checked = $eobj->IsChecked();
		print "  clicked event obj[$eobj] ID[$this_id] current val[$action_val] ischecked[$is_checked]\n" if $step_carp;

		my $action_chk = $eobj->GetLabel();
		print "[$me]  clicked label[$action_chk]\n" if $trace;
		my $stuff = $_wfmgr->gui_ref_ids_panel_n_ctrls($this_id);
		print "[$me]  id-ed stuff, panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
		
		my $ref_cntrls = $_wfmgr->gui_wxapp_ctrls_sync3(key => $stuff->{cname});
		print "[$me]  ref cntrls, push[".$ref_cntrls->{link}->{push}."] push2[".$ref_cntrls->{link}->{push2}."]\n" if $trace;

		## reset other checkboxs to act as a radio check
		if(exists $wxframe->{$stuff->{panel}}->{$ref_cntrls->{link}->{push}}) {
			$wxframe->{$stuff->{panel}}->{$ref_cntrls->{link}->{push}}->SetValue(0);
		}
		if(exists $wxframe->{$stuff->{panel}}->{$ref_cntrls->{link}->{push2}}) {
			$wxframe->{$stuff->{panel}}->{$ref_cntrls->{link}->{push2}}->SetValue(0);
		}
		my $d = {};
		$d->{causality} = $ref_cntrls->{link}->{pull};
		$layout_ptr->store_special_data('causality',$d,$trace);
		$layout_ptr->set_re_state_field(0);
	}
	
	$event->Skip();
	return 1;
}
sub off_focus_combobox_sp {
	my $layout_ptr = undef;
	my $wxframe = undef;
	my $event = undef;
	my $me = 'OFF FOCUS COMBOBOX SP';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$wxframe,$event) = @_;
	} else {
		($wxframe,$event) = @_;
	}
	if(!defined $wxframe) {
		warn "[$me] ERROR the wxframe object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
#	my $_pmgr = $wxframe->_pmgr_handle();
#	my $_wfmgr = $wxframe->_wfmgr_handle();
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
#	my $_pmgr = $main_app->getProcessMgr();
#	my $_wfmgr = $self->wxframe_mgr_ptr();
#	my $_pmgr = $self->process_mgr_ptr();
#	my $_dmgr = $_pmgr->data_manager();
#	my $_smgr = $_pmgr->state_manager();
	my $carp = 1;
	my $step_carp = 1;
	my $inputfield_deduct = 40;

	print "  clicked event[$event] in winframe[$wxframe]\n" if $step_carp;
	my $t = $event->GetEventType();
	print "  clicked event type[$t]\n" if $step_carp;

	if($event->GetEventType() == 10114) {
		print "  combo box clicked\n" if $step_carp;
		my $eobj = $event->GetEventObject();
		print "  clicked event obj[$eobj]\n";
	
		my $action_chk = $eobj->GetLabel();
		print "[$me]  clicked label[$action_chk] - doing nothing\n" if $carp;
	}
	if($event->GetEventType() == 10096) {
#		my $display = $wxframe->_display_handle();
		my $_pmgr = $wxframe->_pmgr_handle();
		my $_smgr = $_pmgr->_stateManager();
		my $dk = $_smgr->get_sp_checkpt_data();
		
		print "  combo box clicked\n" if $step_carp;
		my $eobj = $event->GetEventObject();
		print "  clicked event obj[$eobj]\n" if $step_carp;
	
		my $action_chk = $eobj->GetLabel();
		my $action_val = $eobj->GetCurrentSelection();
		my $select_index = $action_val + 1; # normalize index to start at 1
		my $bid = $eobj->GetId();
		my $sp = $_wfmgr->get_sp_values(); #$self->{SP_VALUES};
		my $sp_loc = $_wfmgr->get_locked_sp_values(); #	$self->{SP_VALUE_LOCKED};
		my $key = $bid - $inputfield_deduct;
		print "[$me] clicked label[$action_chk] val[$action_val] index[$select_index] id[$bid] key[$key] sp[".$sp->{$key}."]\n" if $carp;
		if(exists $sp_loc->{$key} && $sp_loc->{$key}) {
			## return selection to lock position
			print "\tselection is [$key] locked at [".$sp->{$key}."]...\n";
			if(exists $sp->{$key}) {
				my $ind = $sp->{$key}->{index};
				$eobj->SetSelection($ind);
			} else {
				$eobj->SetSelection(0);
			}
			$wxframe->{lock_select_1}->SetFocus();
		} else {
#			if($select_index) {
				$_wfmgr->set_chkpt_to_index_value($key,$select_index);
				#my $dk_ind = $dk->{$action_val};
				#$sp->{$key}->{in} = $dk_ind->{chkin};
				#$sp->{$key}->{out} = $dk_ind->{chkout};
				#$sp->{$key}->{index} = $action_val;
#			} else {
#				$sp->{$key} = undef;
#				delete $sp->{$key};
#			}
		}

	}
	$event->Skip();
	return 1;
}
sub lock_combobox {
	my ($wxframe,$event) = @_;
	my $_wfmgr = $wxframe->_wfmgr_handle();
	print "clicked event for lock/unlock combobox[$event]\n";
	my $t = $event->GetEventType();
	print "clicked event type[$t]\n";
	
	if($event->GetEventType() == 10084) {
#		my $display = $wxframe->_display_handle();
		print "A button was clicked\n";
		my $eobj = $event->GetEventObject();
		print "clicked event obj[$eobj]\n";
	
		my $action = 0;
		my $action_chk = $eobj->GetLabel();
		my $rest = 'Selection';
		if($action_chk=~/^(\w+)\s+(\w+)/i) {
			my $loc = $1;
			$rest = $2;
			print "...matches 1[$loc] 2[$rest]\n";
			if($loc=~/^lock/i) {
				$action = 1;
			} elsif($loc=~/^unlock/i) {
				$action = 0;
			}
		}
		my $bid = $eobj->GetId();
		my $key = $bid - 210;
		print "clicked label[$action_chk] action[$action] id[$bid] key[$key]\n";
#		my $sp_loc = $self->{SP_VALUE_LOCKED};
		my $sp_loc = $_wfmgr->get_locked_sp_values(); #	$self->{SP_VALUE_LOCKED};
		if($action) {
			$sp_loc->{$key} = 1;
			$action_chk = "Unlock " . $rest;
		} else {
			$sp_loc->{$key} = 0;
			$action_chk = "Lock " . $rest;
		}
		$eobj->SetLabel($action_chk);

	}
	return 1;
}
sub lock_parsing_cntrl {
	my $layout_ptr = undef;
	my $wxframe = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' LOCK_PARSING_CNTRL';
	print "[$me] arg size [".scalar(@_)."]  EVENT TRIGGERED>>>\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$wxframe,$event) = @_;
	} else {
		($wxframe,$event) = @_;
	}
	if(!defined $wxframe) {
		warn "[$me] ERROR the wxframe object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
#	my $_pmgr = $main_app->getProcessMgr();
	my $trace = 1;
	my $trace_more = 1;

	print "[$me] clicked event, obj[".$event->GetEventObject()."] type[".$event->GetEventType()."]\n" if $trace;
	print "    [$me] event[$event] in winframe[$wxframe]\n" if $trace_more;


	if($event->GetEventType() == 10084) {
		print "    [$me] click event match {10084} evt type[".$event->GetEventType()."]\n" if $trace_more;
		my $eobj = $event->GetEventObject();
	
		my $action = $_wfmgr->frame_run_states_by_statekey_framekey($wxframe->{WXFRAME_KEY_VALUE},'parse_lock');
		my $this_id = $eobj->GetId();
		my $val = $eobj->GetLabel();
		print "clicked label[$val] action[$action] id[$this_id]\n";

		my $stuff = $_wfmgr->gui_ref_ids_panel_n_ctrls($this_id);
		print "[$me]  id-ed stuff, panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
		
		my $ref_cntrls = $_wfmgr->gui_wxapp_ctrls_sync3(key => $stuff->{cname}, trace => $trace);
		print "[$me]  ref cntrls, pull[".$ref_cntrls->{link}->{pull}."] label push1[".$ref_cntrls->{link}->{push}."] label push2[".$ref_cntrls->{link}->{push2}."]\n" if $trace;
		my $label = $ref_cntrls->{link}->{push};
		my $note = 'Locking';
		if($action) {
			$_wfmgr->frame_run_states_by_statekey_framekey($wxframe->{WXFRAME_KEY_VALUE},'parse_lock',0);
			$note = 'UnLocking';
		} else {
			$_wfmgr->frame_run_states_by_statekey_framekey($wxframe->{WXFRAME_KEY_VALUE},'parse_lock',1);
			$label = $ref_cntrls->{link}->{push2};
		}
		$eobj->SetLabel($label);

		my $mess = "Parsing [$note]";
		$layout_ptr->add_data_textbox($mess,0);

	}
	$event->Skip();
	return 1;
}
## click_signal_options provides "callback" control to on_click_signal in LayoutMain 
sub click_signal_options {
	my ($self,$clabel,$this_id,$sigkey,$sigval,$trace) = @_;
	my $me = __PACKAGE__ . ' SIGNAL OPTIONS';
	my $wxframe = $self->{WXFRAME_PTR};
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();

	print "[$me] check-in, cntrl label[$clabel] id[$this_id] sigkey[$sigkey:$sigval]\n" if $trace;
	my $locked = $_wfmgr->frame_run_states_by_statekey_framekey($wxframe->{WXFRAME_KEY_VALUE},'parse_lock');
	if($locked) {
		print "[$me] check-in, cntrl label[$clabel] id[$this_id] sigkey[$sigkey:$sigval] signal locked[$locked]\n" if $trace;
		return 0;
	}

	## post a notice in message box that the signal was triggered
	my $mess = undef;

	## do timer control...
	if($this_id == 15) {
		## turn on timer
		my $stuff = $_wfmgr->gui_ref_ids_panel_n_ctrls($this_id);
		if(!defined $stuff or !exists $stuff->{cname}) {
			print "[$me] Warning! No cname is available for this id[$this_id]\n";
			die "\tdying to fix [$me]\n";
			return undef;
		}
		print "[$me]  timer id[$this_id], panel[".$stuff->{panel}."] cname[".$stuff->{cname}."] sigkey[$sigkey:$sigval]\n" if $trace;
		$self->timer_control(on_off => 1, cname => $stuff->{cname}, sigkey => $sigkey, trace => $trace);
		$mess = '<<Run dist calcs>>'
	}

	if($this_id==12) {
		$mess = '<<Parsing files>>'
	}
	if($this_id==13) {
		$mess = '<<Parsing topics>>'
	}
	if($this_id==14) {
		$mess = '<<Run code stats>>'
	}
	if($this_id==16) {
		my $stuff = $_wfmgr->gui_ref_ids_panel_n_ctrls($this_id);
		if(!defined $stuff or !exists $stuff->{cname}) {
			print "[$me] Warning! No cname is available for this id[$this_id]\n";
			die "\tdying to fix [$me]\n";
			return undef;
		}
		print "[$me]  timer id[$this_id], panel[".$stuff->{panel}."] cname[".$stuff->{cname}."] sigkey[$sigkey:$sigval]\n" if $trace;
		$self->timer_control(on_off => 1, cname => $stuff->{cname}, sigkey => $sigkey, trace => $trace);
		$mess = '<<make .xls file>>'
	}
	if($this_id==17) {
		$mess = '<<Pre-set codes>>'
	}
	if($this_id==19) {
		$mess = '<<Clean re-codes>>'
	}
	if($mess) {
		$self->add_data_textbox($mess,0);
	}
	

	return 1;
}

sub populate_topic_list {
	my ($self,$this_id,$action_key,$trace) = @_;
	my $me = __PACKAGE__ . " - POPULATE LIST";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();

	my $stuff = $_wfmgr->gui_ref_ids_panel_n_ctrls($this_id);
	print "[$me] gui_ref_ids, id[$this_id] panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;

	my $meth = 'gui_wxapp_ctrls_sync3';
	if($this_id>31) {
		$meth = 'gui_wxapp_ctrls_sync5';
	}
	my $stuff2 = $_wfmgr->$meth(key => $stuff->{cname},trace => $trace);
	print "[$me] cntrl sync's for cname[".$stuff->{cname}."] pull src[".$stuff2->{link}->{pull}."] update1 type[".$stuff2->{type}->{push}."]\n" if $trace;

	if(!exists $wxframe->{$stuff->{panel}}->{$stuff->{cname}}) {
		print "[$me] wxframe cntrl[".$stuff->{cname}."] id[$this_id] does not exist in panel[".$stuff->{panel}."]\n" if $trace;
		return undef;
	}
	my $srcbox = $wxframe->{$stuff->{panel}}->{$stuff->{cname}};
	my $srcbox_index = $srcbox->GetCurrentSelection();
	my $selected_text = $srcbox->GetLabel();
	my $default_chk = 'Select';
	if($this_id==31) {
		$default_chk = 'Select Topic';
	} elsif($this_id==32) {
		$default_chk = 'Select Topic Sentence';
	}

	my $topkey = 'data_coding';
	if($this_id>29 and $this_id<40) {
		$topkey = 'data_coding';
	}
	my $mainkey = $_dmgr->panel_yaml_data_mainkey($stuff->{panel},undef,$trace);
	if(!$mainkey) {
		## assume initial startup and init selection of mainkey (interviewee)
		## populate hot list
#		$self->load_selectable_codes($trace);
	}
	if($this_id==31) {
		$_dmgr->panel_yaml_data_mainkey($stuff->{panel},$action_key,$trace);
		if(exists $stuff2->{link}->{push2}) {
			## reset sentence combobox
			#print "[".__PACKAGE__." - $me] wxframe push cntrl[".$stuff2->{link}->{push2}."] for id[$this_id] resetting combobox in panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
			if(exists $wxframe->{$stuff->{panel}}->{$stuff2->{link}->{push2}}) {
				print "[$me] wxframe push cntrl[".$stuff2->{link}->{push2}."] for id[$this_id] resetting combobox in panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
				my $cbox = $wxframe->{$stuff->{panel}}->{$stuff2->{link}->{push2}};
				$cbox->Clear();
				$cbox->SetLabel("Select New Topic Sentence");
			}
		}
		$mainkey = $_dmgr->panel_yaml_data_mainkey($stuff->{panel},undef,$trace);
	}
	

	if($stuff2->{type}->{push}!~/^combo/i) {
		print "[$me] push-to wxframe cntrl is not a combobox[".$stuff2->{type}->{push}."] id[$this_id] name[".$stuff->{cname}."]\n" if $trace;
		if($this_id==33) {
			my @keys = $self->set_new_sentence($stuff->{cname},$stuff->{panel},$mainkey,$trace);

			if(scalar(@keys)) {
				print "[$me]  sents keys exist[".scalar(@keys)."] key index-0[".$keys[0]."]\n" if $trace;
				if($keys[0]=~/^t(\d+)s(\d+)/i) {
#					my $topic = $1;
#					my $sent = $2;
					my $srcbox_ct = $srcbox->GetCount();
					$self->clear_data_fields($mainkey,$trace);
					$self->populate_data_fields($mainkey,$1,$2,$srcbox_ct,$trace);
					$self->populate_special_fields($mainkey,$1,$2,$trace);
					#print "[".__PACKAGE__." - $me] yml data, size[".scalar(keys %$yml)."] action size[".scalar(keys %{$yml->{$action_key}})."] codes size[".scalar(keys %{$yml->{$action_key}->{codes}})."] sentences size[".scalar(keys %$y)."]\n" if $trace;
					return 1;
				}
			}
			return undef;
		}
		return undef;
	}

	if(!exists $wxframe->{$stuff->{panel}}->{$stuff2->{link}->{push}}) {
		print "[$me] wxframe push cntrl[".$stuff2->{link}->{push}."] for id[$this_id] does not exist in panel[".$stuff->{panel}."] cname[".$stuff->{cname}."]\n" if $trace;
		return undef;
	}

	## grab the "next" combo box control and init it
	my $box = $wxframe->{$stuff->{panel}}->{$stuff2->{link}->{push}};
	$box->SetSelection(0);
	my $sel_val = $box->GetCurrentSelection();
	print "[$me] src combobox[".$stuff->{cname}."] srcbox select index[$srcbox_index] src topic[$selected_text] reset next box to[$sel_val] default[$default_chk] \n" if $trace;
	$box->Clear();
	$box->SetLabel($default_chk);

	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	if($trace) {
		my $chk_key = $mainkey;
		print "[$me] fetched yml data, mainkey[$mainkey] all iname datasize[".scalar(keys %$yml)."] iname subsize[".scalar(keys %{$yml->{$mainkey}})."]\n";
		if($action_key!~/^$mainkey$/i) {
			print "\t\talso action_key[$action_key] does not match mainkey[$mainkey]\n";
		}
	}
	
	my $y = undef;
	my $tblock = undef;
	if($this_id==31) {
		my $topkey_post = "post_parse_data";
		my $yml_post = $_dmgr->get_yaml_data_by_topkey($topkey_post,$trace);
		my $y_topic = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks};
#		my $yctr = 1;
		print "[$me] post_parse yml data, all-size[".scalar(keys %$yml_post)."] mainkey[$mainkey]  inames size[".scalar(keys %{$yml_post->{post_parse}})."] tblocks size[".scalar(keys %{$y_topic})."]\n" if $trace;
		foreach my $tkey (sort {$a cmp $b} keys %$y_topic) {
			$tkey=~/^t(\d+)/i;
			my $key = $tkey . "#" . $y_topic->{$tkey}->{topic};
			$y->{$key} = $1;
#			$yctr++;
		}
	}
	if($this_id==32) {
		my @parts = split "#", $selected_text;
		if(!defined $parts[0]) {
			print "[$me] sentence text[".$selected_text."] mainkey[$mainkey] tkey?".$parts[0]."] cname[".$stuff->{cname}."]\n";
			die "\tdying to fix [$me]\n";
			return undef;
		}
		if($parts[0]!~/t(\d+)/i) {
			print "[$me] sentence key does not match, tskey[".$parts[0]."] in text[".$selected_text."] mainkey[$mainkey] cname[".$stuff->{cname}."]\n";
			die "\tdying to fix [$me]\n";
			return undef;
		}
		my $tindex = $1;

		## rebuild $y with a sorted and keyed list
		my $tkey = "t" . $tindex;
#		my $yy = {};
		my $y_filter = {};

		my $topkey_post = "post_parse_data";
		my $yml_post = $_dmgr->get_yaml_data_by_topkey($topkey_post,$trace);
		print "[$me] yml_post data, mainkey[$mainkey] topickey[$tkey] topic sent map size[".scalar(keys %{ $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map} })."]\n" if $trace;
		

		my $sent_max_index = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{iname_sentence_count};
		my $sentence_map = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map};

		foreach my $ss (keys %$sentence_map) {
			my $key = $sentence_map->{$ss};
			my $_key = $tkey . "s" . $ss;
			my $sent = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$_key}->{sentence};
			$y_filter->{$ss} = $sent;
			print "[$me]   build sentence list for mainkey[$mainkey] tkey[$tkey] tskey[$_key] sindex[$ss] sent val[".$sent."]\n" if $trace;
		}

		## build an selection output hash - displayed fields in drop down list
		my $ctr = 1;
		foreach my $ss (sort {$a <=> $b} keys %$y_filter) {
			my $field = substr($y_filter->{$ss},0,60);
			my $_key = "m" . $ss . "t" . $tindex . "s" . $ss . "#" . $field;
			$y->{$_key} = $ctr;
			$ctr++;
		}

		my $remap = 0;
		if(exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}) {
			if(exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{mapping}) {
				if(exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{mapping}->{remapped_keys} and $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{mapping}->{remapped_keys}) {
					$remap = 1;
				}
			}
		}
#		my $tblock = undef;
		if($remap) {
			my $fkey = $yml_post->{aquad_meta_parse}->{profile}->{$mainkey}->{file}->{src_parse_key};
			$tblock = $yml_post->{parse_multi_struct}->{multi_txt}->{$fkey}->{tblocks_atx}->{$tkey}->{atx_block};
		} else {
			$tblock = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{atx_block};
		}
		
		## also clear sentence fields
		$self->clear_sentence_fields($trace);
		$self->clear_data_fields($mainkey,$trace);
	}
	
	
	if(!defined $y) {
		if($this_id==31) {
			if($action_key) {
				if($action_key=~/^Select /i) {
					warn "[$me] the default mainkey[$action_key] is not useable...ignoring selection, at line[".__LINE__."]\n";
					return undef;
				}
			}
		}
		warn "[$me] y{data hash} is not defined at line[".__LINE__."]\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	
	## populate "next" combobox
	print "[$me] populate box[".$stuff2->{link}->{push}."] in panel[".$stuff->{panel}."] items[".scalar(keys %$y)."]\n" if $trace;
	foreach my $t (sort {$y->{$a} <=> $y->{$b}} keys %$y) {
		$box->Append($t);
	}

	if($this_id==32) {
		if($tblock) {
			$_wfmgr->load_datablock_to_textbox_this_wxframe(wxframe => $wxframe, txtblock => $tblock, trace => $trace);
		}
	}

	if($this_id==31) {
		if($action_key) {
			if($action_key=~/^Select /i) {
				print "[$me] mainkey[$action_key] is NOT an actual SPEAKER key, cname[".$stuff2->{link}->{pull}."] panel[".$stuff->{panel}."]\n" if $trace;
			} else {
				## ensure mainkeys are retained ... so they can be saved...if the dataset is new, this may not happen
				print "[$me] ensure mainkey[$action_key] is an actual RETAINED top, cname[".$stuff2->{link}->{pull}."] panel[".$stuff->{panel}."]\n" if $trace;
				$_dmgr->add_datakey_to_yaml_retain_topkeys($topkey,$action_key,$trace);
			}
		}
	}

	return 1;
}
sub set_topic_block_vview {
	my ($self,$mainkey,$topic_key,$trace) = @_;
	my $me = __PACKAGE__ . " SET TOPIC BLOCK";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
}
sub set_new_sentence {
	my ($self,$cname,$panel,$mainkey,$trace) = @_;
	my $me = __PACKAGE__ . " SET SENTENCE";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();

	my $meth = 'gui_wxapp_ctrls_sync5';
	my $topkey = "data_coding";
	my $topkey_post = "post_parse_data";

	####
	## push 5 fields
	## src == pull
	## push1 = minus - prev
	## push2 = prev
	## push3 = now
	## push4 = next
	## push5 = plus + next
	my $stuff = $_wfmgr->$meth(key => $cname,trace => $trace);

	if(!exists $wxframe->{$panel}->{$stuff->{link}->{pull}}) {
		print "[$me] wxframe push cntrl[".$stuff->{link}->{pull}."] does not exist in panel[".$panel."] cname[".$cname."]\n" if $trace;
		return undef;
	}
	my $srcbox = $wxframe->{$panel}->{$stuff->{link}->{pull}};
	my $srcbox_index = $srcbox->GetCurrentSelection();
	my $selected_text = $srcbox->GetLabel();
	my $srcbox_ct = $srcbox->GetCount();
	my $skey = undef;
	print "[$me] source cname[$cname] panel[$panel] selected text[$selected_text] item ct[$srcbox_ct], pull[".$stuff->{link}->{pull}."]\n" if $trace;
			
	$self->store_new_data($trace);

	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	my $yml_post = $_dmgr->get_yaml_data_by_topkey($topkey_post,$trace);
	#print "[$me] yml_post data, size[".scalar(keys %$yml_post)."] post parse size[".scalar(keys %{$yml_post->{post_parse}})."]\n" if $trace;


	if(!$mainkey) {
		print "[$me] NOTE! mainkey not sent in as ARG. Fetching defaults from _dmgr, cname[".$cname."]\n\n";
		my $keys = $_dmgr->top_key_primary_keys(topkey => $topkey, trace => $trace);
		$mainkey = $keys->{primary_key_1};
		$skey = $keys->{primary_key_2};
	}
	if(!defined $mainkey) {
		print "[$me] WARNING! mainkey not set. Presuming premature clicking of sentence navigator buttons [".$selected_text."] cname[".$cname."]\n\n";
#		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $yml_p = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info};

	if(exists $yml->{$mainkey}->{codes}) {
		print "\n[$me]....hey whoa!! codes exist!!!!!\n\n";
	}
	
	my @parts = split "#", $selected_text;
	if(!defined $parts[0]) {
		print "[$me] sentence key is defined in text[".$selected_text."] mainkey[$mainkey] tskey?[".$parts[0]."] cname[".$cname."]\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	if($parts[0]!~/m(\d+)t(\d+)s(\d+)/i) {
		print "[$me] sentence key does not match, tskey[".$parts[0]."] in text[".$selected_text."] mainkey[$mainkey] cname[".$cname."]\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $map_index = $1; ## sentence list map
	my $topic_index = $2;
	my $sent_index = $3;
	my $tkey = "t".$2;
	my $tskey = "t".$2."s".$3;
	if(!exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$tskey}) {
		print "[$me] sentence key is defined in text[".$selected_text."] mainkey[$mainkey] tskey?[".$tskey."] cname[".$cname."]\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}

	if($map_index) {
		my $topic = $1;
		my $sent = $2;
		my $sentence_map = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map};
		print "[$me] topic[$topic_index] sent_map_index[$map_index] sent_ct_index[$sent_index] select-cntrl index[".$srcbox_index."] text[".$parts[1]."] selected sentence[$selected_text]\n" if $trace;

		## this is a messy POS routine...change when the stink wears off...
		my @pkeys = ();
		my $pre2key = undef;
		my $test = $map_index - 2;
		if($test > 0) {
#			if(exists $sentence_map->{$test} or !$sentence_map->{$test}) {
#				$pre2key = $sentence_map->{$test}
#			} else {
				$pre2key = "t".$topic_index."s".($map_index-2);
#			}
		}
		push @pkeys, $pre2key;
		my $prekey = undef;
		$test = $map_index - 1;
		if($test > 0) {
#			if(exists $sentence_map->{$test} or !$sentence_map->{$test}) {
#				$prekey = $sentence_map->{$test}
#			} else {
				$prekey = "t".$topic_index."s".($map_index-1);
#			}
		}
		push @pkeys, $prekey;
		push @pkeys, $tskey;
		my $postkey = undef;
		$test = $map_index + 1;
		if($map_index < $srcbox_ct) {
#			if(exists $sentence_map->{$test} or !$sentence_map->{$test}) {
#				$postkey = $sentence_map->{$test}
#			} else {
				$postkey = "t".$topic_index."s".($map_index+1);
#			}
#			$postkey = "t".$1."s".($map_index+1);
		}
		push @pkeys, $postkey;
		my $post2key = undef;
		$test = $map_index + 2;
		if($map_index < $srcbox_ct) {
#			if(exists $sentence_map->{$test} or !$sentence_map->{$test}) {
#				$post2key = $sentence_map->{$test}
#			} else {
				$post2key = "t".$topic_index."s".($map_index+2);
#			}
#			$post2key = "t".$1."s".($map_index+2);
		}
		push @pkeys, $post2key;

		my %setlabels = ( 1 => '', 2 => '', 3 => '');
		my %setcntrls = ( 1 => '', 2 => '', 3 => '');
		my %setskeys = ( 1 => '', 2 => '', 3 => '');
		my %prelabels = ( 1 => '', 2 => '', 3 => '');
		my %recodes = ( 1 => 0, 2 => 0, 3 => 0);
		my @pushes = ('push','push2','push3','push4','push5');
		my $skey = $tskey;
		my $ktr = 1;
		for (my $i=0; $i<scalar(@pushes); $i++) {
			my $push = $pushes[$i];
			my $pkey = $pkeys[$i];
			if(defined $stuff->{link}->{$push} and exists $wxframe->{$panel}->{$stuff->{link}->{$push}}) {
				my $ptext = '';
				my $recode = 0;
				print "  [$me] key mapping loop, push key[$push] push cname[".$stuff->{link}->{$push}."] >>" if $trace;
				my $str = " NULL";
				if(defined $pkey) {
					$ptext = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$pkey}->{sentence};
					if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$pkey}) {
						$recode = 1;
					}
					$str = " for prekey[$pkey] recoded?[$recode]";
				}
				$prelabels{$ktr} = $wxframe->{$panel}->{$stuff->{link}->{$push}}->GetLabel();
				$setcntrls{$ktr} = $stuff->{link}->{$push};
				$setlabels{$ktr} = $ptext;
				$setskeys{$ktr} = $pkey;
				$recodes{$ktr} = $recode;
				print $str . "  << push arr index[$ktr]\n" if $trace;
				$ktr++;
			}
		}
		my $sentence_text = $parts[1];
		if(exists $setlabels{2} and $setlabels{2}) { ## the selected sentence must exist!
			$skey = $setskeys{2};
			$sentence_text = $setlabels{2};
			foreach my $ctr (sort {$a <=> $b} keys %setlabels) {
				$prelabels{$ctr} = $setlabels{$ctr};
				if($trace) {
					print "  [$me] set labels loop, tskey[";
					if(defined $setskeys{$ctr}) {
						print $setskeys{$ctr};
					} else {
						print "undef";
					}
					print "] cntrl name[".$setcntrls{$ctr}."] str[".$setlabels{$ctr}."] skey[$skey]\n";
				}
			}
		}
		foreach my $ctr (sort {$a <=> $b} keys %prelabels) {
			$wxframe->{$panel}->{$setcntrls{$ctr}}->SetLabel($prelabels{$ctr});
		}
		$_dmgr->top_key_primary_keys(topkey => $topkey, primary_key_1 => $mainkey, primary_key_2 => $skey, trace => $trace);
		
#		if(exists $yml->{$mainkey}->{re_codes}->{sentences} and scalar(keys %{$yml->{$mainkey}->{re_codes}->{sentences}})) {
#				foreach my $ss (keys %{$yml->{$mainkey}->{re_codes}->{sentences}}) {
#					print "[$me]..............................recodes skey[$ss]\n";
#				}
#			}

		print "[$me] setting new sentence[$skey] for [$mainkey] on panel[$panel] topkey[$topkey]\n" if $trace;
		return ($skey,$sentence_text);

	}
	

	return ();
}
sub clear_sentence_fields {
	my ($self,$trace) = @_;
	my $me = __PACKAGE__ . " CLEAR SENTENCE FIELDS";
	my $wxframe = $self->{WXFRAME_PTR};
#	my $_wfmgr = $self->wxframe_mgr_ptr();
#	my $_pmgr = $self->process_mgr_ptr();
#	my $_dmgr = $_pmgr->data_manager();
	my $panel = 'mainpanel';

	my %pushes = ('1' => 'sentence_text_selected_pre','2' => 'sentence_text_selected','3' => 'sentence_text_selected_post');
	print "[$me] clearing [".scalar(keys %pushes)."] fields on panel[$panel]\n" if $trace;

	foreach my $key (keys %pushes) {
		$wxframe->{$panel}->{$pushes{$key}}->SetLabel('');
	}
	return 1;
}
sub clear_data_fields {
	my ($self,$mainkey,$trace) = @_;
	my $me = __PACKAGE__ . " CLEAR DATA";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	
	my @grids = ('grid_aspect','grid');
	my $grids = $wxframe->getWxGridsforFrame();

	if(!$self->store_new_data($trace)) {
		print "[$me] data does not need to be stored\n" if $trace;
#		return undef;
	}

	my $topkey = "data_coding";
	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	if(!$mainkey) {
		my $keys = $_dmgr->top_key_primary_keys(topkey => $topkey, trace => $trace);
		$mainkey = $keys->{primary_key_1};
#		$skey = $keys->{primary_key_2};
	}

#		if(exists $yml->{$mainkey}->{re_codes}->{sentences} and scalar(keys %{$yml->{$mainkey}->{re_codes}->{sentences}})) {
#				foreach my $ss (keys %{$yml->{$mainkey}->{re_codes}->{sentences}}) {
#					print "[$me]..............................recodes skey[$ss]\n";
#				}
#			}


	foreach my $grid_key (@grids) {
#		my $topkey = "data_coding";
		if($grid_key=~/^grid_aspect$/i) {
#			my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
			#$yml->{run_proc}->{grids}->{grid_aspect}->{matrix}->{$row}->{$col} = $matrix->{$row}->{$col};
			print "[$me] yml [$grid_key] data, size rows[".scalar(keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}})."] aspects size[".scalar(keys %{$yml->{runlinks}->{aspects}})."]\n" if $trace;
			#$_dmgr->panel_yaml_data_mainkey('aspectpanel',$mainkey);
			my $mkey = $_dmgr->panel_yaml_data_mainkey('aspectpanel',undef,$trace);
			if(!$mkey) {
				$_dmgr->panel_yaml_data_mainkey('aspectpanel',$mainkey);
			}
			my $grid = $grids->{$grid_key};
			if(exists $yml->{run_proc}->{grids}->{$grid_key}->{matrix} and scalar(keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}})) {
				foreach my $row (keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}}) {
					if($yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}=~/HASH/i and scalar(keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}})) {
						foreach my $col (keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}}) {
							if($col < 5) {
								next;
							}
							$yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$col} = undef;
							my $c = $col - 1;
							my $r = $row - 1;
							my $null = '';
							$grid->SetCellValue($r, $c, $null);
							$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(255,255,255));
						}
					}
				}
			}
#			$yml->{run_proc}->{grids}->{$grid_key}->{data_keys}->{$mainkey}->{$skey} = 1;
			print "[$me] this grid[$grid_key] was cleared...\n" if $trace;
		}
		if($grid_key=~/^grid$/i) {
#			my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
			print "[$me] yml [$grid_key] data, size rows[".scalar(keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}})."]\n" if $trace;

			my $mkey = $_dmgr->panel_yaml_data_mainkey('gridpanel',undef,$trace);
			if(!$mkey) {
				$_dmgr->panel_yaml_data_mainkey('gridpanel',$mainkey);
			}
			my $grid = $grids->{$grid_key};
			my $null = '';
			if(exists $yml->{run_proc}->{grids}->{$grid_key}->{matrix} and scalar(keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}})) {
				foreach my $row (keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}}) {
					if($yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}=~/HASH/i and scalar(keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}})) {
						foreach my $col (keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}}) {
							if($col < 1) {
								next;
							}
							delete $yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$col};
							my $c = $col - 1;
							my $r = $row - 1;
							$grid->SetCellValue($r, $c, $null);
							if($col > 5) {
								$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(255,255,255));
							}
						}
					}
					delete $yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row};
				}
			}
		}
	}
	return 1;
}
sub populate_data_fields {
	my ($self,$mainkey,$topicct,$sentct,$srcbox_ct,$trace) = @_;
	my $me = __PACKAGE__ . " - POPULATE DATA";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	
	my %multi_inames = ('G3MP1'=>1,'D1MP1'=>2,'D0MP1'=>3,'J0MP1'=>4,);
	my $details_trace = 0;
	my $matrix_trace = 0;
	my $pop_trace = 0;
	my $keys_trace = 0;
	
	my @grids = ('grid_aspect','grid');
	my $grids = $wxframe->getWxGridsforFrame();

	my $topkey = "data_coding";
	my $topkey_post = "post_parse_data";
	my $skey = "t" . $topicct . "s" . $sentct;
	my $tkey = "t" . $topicct;
	my $tskey_in = "t" . $topicct . "s" . $sentct; ## not sure why I label this so....
	my $_tskey = "t" . $topicct . "s" . $sentct;
	
	$_dmgr->top_key_primary_keys(topkey => $topkey, primary_key_1 => $mainkey, primary_key_2 => $skey, trace => $trace);
	my $mkey = 'null';
	if($mainkey) { $mkey = $mainkey; }
	print "[$me] key values, main[$mkey] skey[$skey] grid ct[".scalar(@grids)."]\n" if $trace;

	my $s2key = undef;
	if(!$mainkey) {
		my $keys = $_dmgr->top_key_primary_keys(topkey => $topkey, trace => $trace);
		$mainkey = $keys->{primary_key_1};
		$s2key = $keys->{primary_key_2};
	}
#	print "[$me] after fetching primary key values, main[$mainkey] s2key[$s2key] \n" if $trace;
	
	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	print "[$me] yml data, size[".scalar(keys %$yml)."] runlinks size[".scalar(keys %{$yml->{runlinks}})."] aspects size[".scalar(keys %{$yml->{runlinks}->{aspects}})."]\n" if $trace;
	my $yml_post = $_dmgr->get_yaml_data_by_topkey($topkey_post,$trace);
	print "[$me] yml_post data, size[".scalar(keys %$yml_post)."] post parse size[".scalar(keys %{$yml_post->{post_parse}})."]\n" if $trace;

	if(!exists $yml->{run_proc}->{states}->{sentences}) {
		$yml->{run_proc}->{states}->{sentences} = {};
	}
	my $s_state = $yml->{run_proc}->{states}->{$mainkey}->{sentences};

	foreach my $grid_key (@grids) {
		my $matrix = {};
		if($grid_key=~/^grid_aspect$/i) {
			my $mkey = $_dmgr->panel_yaml_data_mainkey('aspectpanel',undef,$trace);
			if(!$mkey) {
				$_dmgr->panel_yaml_data_mainkey('aspectpanel',$mainkey);
			}
		
			my $y = $yml->{runlinks}->{aspects};
			my $col = 3;
			my $row = 1;
			foreach my $aspect (sort {$y->{$a} <=> $y->{$b}} keys %$y) {
				my $num_col = $col - 1;
				$matrix->{$row}->{$num_col} = $y->{$aspect};
				$matrix->{$row}->{$col} = $aspect;
				$row++;
			}
			my $remap_keys = 0;
			if(exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}) {
				if(exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{mapping}) {
					if(exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{mapping}->{remapped_keys} and $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{mapping}->{remapped_keys}) {
						$remap_keys = 1;
					}
				}
			}
			if(!$remap_keys and (!exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey} or !scalar(keys %{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}}))) {
				print "\n[$me] grid[$grid_key] skey[$skey] !!! FAIL grid data, yml structure is bad (re_codes) data, [$mainkey} size[".scalar(keys %{$yml->{$mainkey}})."] re_codes size[".scalar(keys %{$yml->{$mainkey}->{re_codes}})."] sentences size[".scalar(keys %{$yml->{$mainkey}->{re_codes}->{sentences}})."]\n\n";
			}
			my $_tskey = $skey;
			if($remap_keys) {
				if(exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}) {
					if(!exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map}->{$sentct}) {
						print "\n[$me] grid[$grid_key] skey[$skey] !!!! FAIL key remapping on[$sentct] yml structure is bad (tblock) data, [$mainkey} size[".scalar(keys %{$yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}})."] re_mapped keys[".scalar(keys %{$yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map}})."]\n\n";
					} else {
						$_tskey = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map}->{$sentct};
					}
				} else {
					print "\n[$me] grid[$grid_key] skey[$skey] !!!! FAIL key remapping on[$sentct] yml structure is bad (tblock) data, [$mainkey} size[".scalar(keys %{$yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}})."] re_mapped keys[".scalar(keys %{$yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map}})."]\n\n";
				}
			}
			print "[$me] [$mainkey] grid[$grid_key] unmapped skey[$skey] remapped tskey[$_tskey] remap toggle[$remap_keys] yml aspect (re_codes) data\n" if $trace;
#			print "[$me] [$mainkey] grid[$grid_key] tskey[$_tskey] unmapped skey[$skey] yml aspect (re_codes) data, size[".scalar(keys %{$yml->{$mainkey}})."] re_codes size[".scalar(keys %{$yml->{$mainkey}->{re_codes}})."] sentences size[".scalar(keys %{$yml->{$mainkey}->{re_codes}->{sentences}})."]\n" if $trace;
			my $sentence_info = undef;
			if($remap_keys) {
				$sentence_info = $yml->{$mainkey}->{re_codes}->{sentences}->{$skey};
			} else {
				$sentence_info = $yml->{$mainkey}->{re_codes}->{sentences}->{$skey};
			}
			if(defined $sentence_info and scalar(keys %$sentence_info)) {
				#if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$_tskey}->{codes} and scalar(keys %{$yml->{$mainkey}->{re_codes}->{sentences}->{$_tskey}->{codes}})) {
#				foreach my $ss (keys %{$yml->{$mainkey}->{re_codes}->{sentences}}) {
#					print ".......skey[$ss]\n";
#				}
				print "[$me] [$mainkey] grid[$grid_key] tskey[$_tskey] unmapped skey[$skey] yml aspect (re_codes) data, size[".scalar(keys %{$yml->{$mainkey}})."] re_codes size[".scalar(keys %{$yml->{$mainkey}->{re_codes}})."] sentences size[".scalar(keys %{$yml->{$mainkey}->{re_codes}->{sentences}})."]\n" if $trace;
				foreach my $code (keys %{ $sentence_info->{aspects} }) {
					foreach my $row (keys %$matrix) {
						my $sub = $matrix->{$row};
						my $aspect = $sub->{3};
						my $eleven = 11;
						if($code=~/^$aspect/i) {
							my $rating = $sentence_info->{aspects}->{$code};
							my $rcol = $eleven - $rating;
							$matrix->{$row}->{$rcol} = 1;
						}
					}
				}
			}
			my $grid = $grids->{$grid_key};
			if(defined $matrix and scalar(keys %$matrix)) {
				foreach my $row (keys %$matrix) {
					if($matrix->{$row}=~/HASH/i and scalar(keys %{$matrix->{$row}})) {
						foreach my $col (keys %{$matrix->{$row}}) {
							if($col < 5) {
								next;
							}
							$yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$col} = $matrix->{$row}->{$col};
							my $c = $col - 1;
							my $r = $row - 1;
							$grid->SetCellValue($r, $c, $matrix->{$row}->{$col});
							$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(0,255,128));
						}
					}
				}
			}
			print "[$me] [$mainkey] grid[$grid_key] has been loaded...continuing\n" if $trace;
		}
		if($grid_key=~/^grid$/i) {

			print "[$me] [$mainkey] grid[$grid_key] skey[$skey] curr sentence ct[$sentct]  yml topkeys size[".scalar(keys %$yml)."] main[$mainkey] size[".scalar(keys %{$yml->{$mainkey}})."] " if $trace;
#			my $y = $yml->{$mainkey}->{atx_txt}->{sentences_info};
			my $y = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info};
			my $ys_codes = $yml_post->{post_parse}->{$mainkey}->{codes}->{sentences}->{$skey}->{codes};
			$s_state->{$skey} = 'tainted';

			my $sentence_info = undef;
			if(exists $yml->{$mainkey}->{new_re_codes}) {
				$sentence_info = $yml->{$mainkey}->{new_re_codes}->{sentences}->{$skey};
			} elsif(exists $yml->{$mainkey}->{re_codes}) {
				$sentence_info = $yml->{$mainkey}->{re_codes}->{sentences}->{$skey};
			}
			if(defined $sentence_info and scalar(keys %$sentence_info)) {
#			if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{codes} and scalar(keys %{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{codes}})) {
#				$y = $yml->{$mainkey}->{re_codes}->{sentences};
				$ys_codes = $sentence_info->{codes};
				$s_state->{$skey} = 'clear';
#				print " RE codes size[".scalar(keys %{$yml->{$mainkey}->{re_codes}})."]" if $trace;
			}
			print " sentences size[".scalar(keys %$y)."]\n" if $trace;
			if(!exists $y->{$skey}) {
				warn "[$me] [$mainkey] this sentence key[$skey] does not exist! line[".__LINE__."]\n";
				return 0;
			}

#			$new_data_postparse->{post_parse}->{$iname}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map}->{$k} = $tskey;
			if(!exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$_tskey}) {
				print "\n[$me}[$mainkey] .. ERROR, fail at finding tskey[$_tskey] for [$mainkey]\n\n";
			}
			my $sent_index = $sentct;
			if(!exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}) {
				print "\n[$me}[$mainkey] .. ERROR, fail at finding count values for tskey[$_tskey] for [$mainkey]\n\n";
			}
			if($sent_index != $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{atx_block_sentence}) {
				print "\n[$me} [$mainkey] .. ERROR, sentence indexing[$sent_index][".$yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{atx_block_sentence}."] is bad at tskey[$_tskey] for [$mainkey]\n\n";
			}
			my $sent_max_index = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{iname_sentence_count};
			my $sentence_map = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{sentence_map};

			my $multi_parse = 0;
			if(exists $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{multi_parse_structure} and $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{tblocks}->{$tkey}->{multi_parse_structure}) {
				$multi_parse = 1;
			}
			
			## sentence map should be one-to-one with sentence count
			## ... unless the map is for a multi-parse file
#			my $y_filter = {};
			my $sent_map_index = $sent_index;
			my %multi_codes = ();
			if($multi_parse) {
				## find remap
				my $fkey = undef;
				if(exists $multi_inames{$mainkey}) {
					delete $multi_inames{$mainkey};
				}
#				foreach my $nind (keys %multi_inames) {
				if(exists $yml_post->{aquad_meta_parse}->{profile}->{$mainkey}) {
					if(exists $yml_post->{aquad_meta_parse}->{profile}->{$mainkey}->{file}->{src_parse_key}) {
						$fkey = $yml_post->{aquad_meta_parse}->{profile}->{$mainkey}->{file}->{src_parse_key};
					}
				}
				if(!exists $sentence_map->{$sent_index} or !$sentence_map->{$sent_index}) {
					print "\n[$me} [$mainkey] .. ERROR, sentence map is bad at index[$sent_index][".$yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$_tskey}->{counts}->{atx_block_sentence}."] tskey[$_tskey] for [$mainkey]\n\n";
				}
				my $remapkey = $sentence_map->{$sent_index};
				my $_re_tskey = undef;
				if($fkey) {
					if(exists $yml_post->{parse_multi_struct}->{multi_txt}->{$fkey}) {
						if(exists $yml_post->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$remapkey}) {
							$_re_tskey = $yml_post->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$remapkey}->{tskey_map};
						}
					}
				}
				my $sent_diff = 5;
				if($_re_tskey=~/^t(\d+)s(\d+)$/i) {
					my $tkey = "t".$1;
					my $multi_sent_index = $2;
					my $multi_low = 1;
					if($multi_sent_index - $sent_diff > 0) {
						$multi_low = $multi_sent_index - $sent_diff;
					}
					my $multi_max = $yml_post->{parse_multi_struct}->{multi_txt}->{$fkey}->{tblocks_atx}->{$tkey}->{all_iname_sentence_count};
					my $multi_hi = $multi_max;
					if($multi_sent_index + $sent_diff < $multi_max) {
						$multi_hi = $multi_sent_index + $sent_diff;
					}
					for (my $ii=$multi_low; $ii<$multi_hi; $ii++) {
						my $_m_tskey = $tkey . "s" . $ii;
						my $miname = $yml_post->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$_m_tskey}->{iname};
						if(!exists $multi_inames{$miname}) {
							## not tracking this one
							next;
						}
						my $_re_m_tskey = $yml_post->{parse_multi_struct}->{multi_txt}->{$fkey}->{sentence_struct}->{$_m_tskey}->{tskey_map};

						my $sentence_info = undef;
						if(exists $yml->{$miname}->{new_re_codes}) {
							$sentence_info = $yml->{$miname}->{new_re_codes}->{sentences}->{$_re_m_tskey};
						} elsif(exists $yml->{$miname}->{re_codes}) {
							$sentence_info = $yml->{$miname}->{re_codes}->{sentences}->{$_re_m_tskey};
						}
						if(defined $sentence_info and scalar(keys %$sentence_info)) {
							if(exists $sentence_info->{codes}) {
								foreach my $_ind (keys %{ $sentence_info->{codes} }) {
									my $cc = $sentence_info->{codes}->{$_ind};
									$multi_codes{$miname}{$cc} = 1;
								}
							}
						}
					}
					
				}	
			}

#			foreach my $ss (keys %$sentence_map) {
#				my $key = $sentence_map->{$ss};
#				if($_tskey=~/$key$/i) {
#					$sent_map_index = $ss;
#				}
#				my $sent = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$key}->{sentence};
#				$y_filter->{$ss} = $sent;
#				print "[$me] [$mainkey]   build sentence list, tkey[$tkey] ss[$ss] tskey[$key] sent val[".$sent."]\n" if $trace;
#			}

			if(!$sent_map_index) {
				warn "[$me] [$mainkey] not able to locate sentence map index for skey[$skey] line[".__LINE__."]\n";
				return 0;
			}

			my @skeys = ();
			my @skeycols = ();
			my $ssctr = -3;
			for (my $i=-3; $i<4; $i++) {
				## match array walk to map position
				## match array walk to map position
				my $i_comp = $i + $sent_map_index; 
				my $skey_ss = undef;
				print "[$me] [$mainkey].. matrix keys..i[$i] sent_index[$sent_map_index] i_comp[$i_comp]" if $keys_trace;
				if($i_comp > 0 and $i_comp < ($sent_max_index + 1)) {
					if(exists $sentence_map->{$i_comp}) {
#						$skey_ss = $sentence_map->{$i_comp};
						$skey_ss = $tkey . "s" . $i_comp;
					}
					print " skey_ss[$skey_ss] tskey_in[$tskey_in]" if $keys_trace;
				}
				push @skeys,$skey_ss;
				push @skeycols,$ssctr;
				print " ssctr[$ssctr]\n" if $keys_trace;
				$ssctr++;
			}

#			for (my $ss=($sent_index-3); $ss<($sent_index+4); $ss++) {
#				my $skey_ss = undef;
#				print "[$me].. matrix keys..ss[$ss] sent_index[$sent_index]" if $keys_trace;
#				if($ss > 0 and $ss < ($sent_max_index + 1)) {
#					if(exists $sentence_map->{$ss}) {
#						$skey_ss = $sentence_map->{$ss};
#					}
#					if($ss==$sent_index) {
#						$skey_ss = $tskey_in;
#					}
#					print "skey_ss[$skey_ss] tskey_in[$tskey_in]" if $keys_trace;
#				}
#				
#				push @skeys,$skey_ss;
#				push @skeycols,$ssctr;
#				print "ssctr[$ssctr]\n" if $keys_trace;
#				$ssctr++;
#			}
			


			my $col = 3;
			my $row = 1;
			my $s_col = $col + 2;
			my $num_col = $col - 1;
			my $pres_col = $col + 6;
			my $start_checked_cols = $col + 3;
			my $end_checked_cols = $start_checked_cols + 8;
			if($multi_parse) {
				$end_checked_cols = $end_checked_cols + 3;
			}

			my %code_ctr = ();
			my $pre_matrix = {};
			my $ctr = 1;
			foreach my $cindex (sort {$a <=> $b} keys %$ys_codes) {
				$code_ctr{$ys_codes->{$cindex}} = $ctr;
				$pre_matrix->{$ys_codes->{$cindex}}->{$pres_col} = 1;
				$ctr++;

			}
			for (my $i=0; $i<scalar(@skeycols); $i++) {
				my $sskey = $skeys[$i];
				print "[$me] [$mainkey].. matrix..keys-codes..i[$i]" if $keys_trace;
				if(defined $sskey) {
					if($sskey eq $tskey_in) {
						## added in prev loop
						print " current sentence\n" if $keys_trace;
						next;
					}
					print " sskey[$sskey]" if $keys_trace;
					my $_codes = undef;
					my $re = 0;
					if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$sskey}) {
						if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$sskey}->{codes} and scalar(keys %{ $yml->{$mainkey}->{re_codes}->{sentences}->{$sskey}->{codes} })) {
							$_codes = $yml->{$mainkey}->{re_codes}->{sentences}->{$sskey}->{codes};					
							$s_state->{$sskey} = 'clear';
							$re = 1;
						}
					}
					if(!$re) {
						if(exists $yml_post->{post_parse}->{$mainkey}->{codes}->{sentences}->{$sskey}) {
							$_codes = $yml_post->{post_parse}->{$mainkey}->{codes}->{sentences}->{$sskey}->{codes};
							$s_state->{$sskey} = 'tainted';
						}
					}
					print " state[".$s_state->{$sskey}."] re[$re] code ct[".scalar(keys %$_codes)."]" if $keys_trace;
					foreach my $c2index (keys %$_codes) {
						my $code2 = $_codes->{$c2index};
						if(!exists $code_ctr{$code2}) {
							my $size = scalar(keys %code_ctr) + 1;
							$code_ctr{$code2} = $size;
						}
						my $scol = $pres_col + $skeycols[$i];
						$pre_matrix->{$code2}->{$scol} = $re;
#						print "matrix..load active flags..row[$row]col[$i] code[$code] src_RE[".$pre_matrix->{$code}->{$i}."] col_start[$start_checked_cols]col_end[$end_checked_cols]\n" if $pop_trace;
					}
				}
				print "\n" if $keys_trace;
			}

			my $plus_col_ctr = 13;
			print "[$me] [$mainkey] multi-iname load " if $trace;
			foreach my $_iname (sort {$multi_inames{$a} <=> $multi_inames{$b}} keys %multi_inames) {
				print "[$_iname]:[" if $trace;
			
				if(exists $multi_codes{$_iname}) {
					print "codes:".scalar(keys %{ $multi_codes{$_iname} }).":loaded" if $trace;
					foreach my $_code (keys %{ $multi_codes{$_iname} }) {
#					$multi_codes{$miname}{$cc} = 1;
						$pre_matrix->{$_code}->{$plus_col_ctr} = 1;
						if(!exists $code_ctr{$_code}) {
							my $size = scalar(keys %code_ctr) + 1;
							$code_ctr{$_code} = $size;
						}
					}
				}
				print "] " if $trace;
				$plus_col_ctr++;
			}
			print "\n" if $trace;
			foreach my $code (sort {$code_ctr{$a} <=> $code_ctr{$b}} keys %code_ctr) {
				$matrix->{$row}->{$num_col} = $code_ctr{$code};
				$matrix->{$row}->{$col} = $code;
				if(exists $y->{$skey}->{begin}->{chars} and $y->{$skey}->{begin}->{chars}) {
					$matrix->{$row}->{$s_col} = $y->{$skey}->{begin}->{chars};
				}
				for (my $i=$start_checked_cols; $i<($end_checked_cols+1); $i++) {
					if(exists $pre_matrix->{$code}->{$i}) {
						$matrix->{$row}->{$i} = 1;
						print "[$me].. matrix..load active flags..row[$row]col[$i] code[$code] src_RE[".$pre_matrix->{$code}->{$i}."] col_start[$start_checked_cols]col_end[$end_checked_cols]\n" if $pop_trace;
					}
				}
				$row++;
			}


			my $grid = $grids->{$grid_key};
			my $panel = 'mainpanel';
			if(defined $matrix and scalar(keys %$matrix)) {
				foreach my $row (keys %$matrix) {
					if($matrix->{$row}=~/HASH/i and scalar(keys %{$matrix->{$row}})) {
						foreach my $col (keys %{$matrix->{$row}}) {
							if(!defined $matrix->{$row}->{$col}) {
								print "[$me].......set matrix...row[$row] col[$col] something funky...no value for this cell!\n" if $matrix_trace;
								next;
							}
							$yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$col} = $matrix->{$row}->{$col};
							my $c = $col - 1;
							my $r = $row - 1;
							$grid->SetCellValue($r, $c, $matrix->{$row}->{$col});
							if($col < 6) {
								$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(255,255,128));
							} elsif($col==9) {
								$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(0,255,19));
							} elsif($col<13) {
								$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(0,255,128));
							} else {
								$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(255,255,128));
							}
							print "[$me].......set matrix...row[$row] col[$col] val[".$matrix->{$row}->{$col}."]\n" if $matrix_trace;
						}
					}
				}
			}
			if($s_state->{$skey}=~/^tainted$/i) {
				my $field = 'sentence_state';
				if(exists $wxframe->{$panel}->{$field}) {
					$wxframe->{$panel}->{$field}->SetLabel('Not RE');
				}
			} elsif($s_state->{$skey}=~/^clear$/i) {
#				my $panel = 'mainpanel';
				my $field = 'sentence_state';
				if(exists $wxframe->{$panel}->{$field}) {
					$wxframe->{$panel}->{$field}->SetLabel('rCoded');
				}
			}
			my $sfield = 'sentence_tskey';
			if(exists $wxframe->{$panel}->{$sfield}) {
				$wxframe->{$panel}->{$sfield}->SetLabel($skey);
			}

#			$yml->{run_proc}->{grids}->{$grid_key}->{data_keys}->{$mainkey}->{$skey} = 1;
			print "[$me] grid[$grid_key] has been loaded...code populating complete, state[".$s_state->{$skey}."]\n" if $trace;
		}
	}

	$_dmgr->set_topkey_dirty($topkey,0,$trace);
	return 1;
}
sub populate_special_fields {
	my ($self,$mainkey,$topicct,$sentct,$trace) = @_;
	my $me = __PACKAGE__ . " - POPULATE DATA";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	
	my $topkey = "data_coding";
	my $skey = "t" . $topicct . "s" . $sentct;
	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
#	$_dmgr->top_key_primary_keys(topkey => $topkey, primary_key_1 => $mainkey, primary_key_2 => $skey, trace => $trace);
	my $mkey = 'null';
	if($mainkey) { $mkey = $mainkey; }
#	print "[$me] key values, main[$mkey] skey[$skey] grid ct[".scalar(@grids)."]\n" if $trace;

	my $s2key = undef;
	if(!$mainkey) {
		my $keys = $_dmgr->top_key_primary_keys(topkey => $topkey, trace => $trace);
		$mainkey = $keys->{primary_key_1};
		$s2key = $keys->{primary_key_2};
	}
	
	my $panel = 'specialpanel';
	my @cause = ('none','cause_n_effect','cause','effect');
	for (my $i=1; $i<scalar(@cause); $i++) {
		$wxframe->{$panel}->{$cause[$i]}->SetValue(0);
	}
	if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{causality}) {
		if($yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{causality}=~/^(\d)$/) {
			if($1 == 1) {
				$wxframe->{$panel}->{$cause[1]}->SetValue(1);
				$wxframe->{$panel}->{$cause[2]}->SetValue(0);
				$wxframe->{$panel}->{$cause[3]}->SetValue(0);
			} elsif($1 == 2) {
				$wxframe->{$panel}->{$cause[2]}->SetValue(1);
				$wxframe->{$panel}->{$cause[1]}->SetValue(0);
				$wxframe->{$panel}->{$cause[3]}->SetValue(0);
			} elsif($1 == 3) {
				$wxframe->{$panel}->{$cause[3]}->SetValue(1);
				$wxframe->{$panel}->{$cause[1]}->SetValue(0);
				$wxframe->{$panel}->{$cause[2]}->SetValue(0);
			}
		}
#		my $causality = $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{causality};
	}
	$wxframe->{$panel}->{perspective_view}->SetSelection(0);
	$wxframe->{$panel}->{perspective_level}->SetSelection(0);
	$wxframe->{$panel}->{stakeholder_primary_role}->SetSelection(0);
	$wxframe->{$panel}->{sub_role_text}->SetLabel('');
	if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{view}->{orientation}) {
		if(exists $yml->{runlinks}->{perspective_views}->{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{view}->{orientation}}) {
			my $index = $yml->{runlinks}->{perspective_views}->{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{view}->{orientation}};
			$wxframe->{$panel}->{perspective_view}->SetSelection($index);
		}
	}
	if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{view}->{level}) {
		if(exists $yml->{runlinks}->{perspective_levels}->{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{view}->{level}}) {
			my $index = $yml->{runlinks}->{perspective_levels}->{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{view}->{level}};
			$wxframe->{$panel}->{perspective_level}->SetSelection($index);
		}
	}
	if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{primary}) {
		if(exists $yml->{runlinks}->{stakeholder_primary_roles}->{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{primary}}) {
			my $index = $yml->{runlinks}->{stakeholder_primary_roles}->{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{primary}};
			$wxframe->{$panel}->{stakeholder_primary_role}->SetSelection($index);
		}
	}
	if(exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{subrole}) {
		if(exists $yml->{runlinks}->{stakeholder_primary_roles}->{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{subrole}}) {
			my $index = $yml->{runlinks}->{stakeholder_primary_roles}->{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{subrole}};
			$wxframe->{$panel}->{stakeholder_primary_role}->SetSelection($index);
		}
		my $roletext = $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{subrole};
		$wxframe->{$panel}->{sub_role_text}->SetLabel($roletext);
	}
	return 1;
}
sub store_new_data {
	my ($self,$trace) = @_;
	my $me = __PACKAGE__ . " - STORE NEW DATA";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();

	my $temp_trace = 0;
	my $store_trace = 1;

	my @grids = ('grid_aspect','grid');
	my $grids = $wxframe->getWxGridsforFrame();

	my $topkey = "data_coding";
	my $topkey_post = "post_parse_data";
	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	my $yml_post = $_dmgr->get_yaml_data_by_topkey($topkey_post,$trace);
	if(!exists $yml->{run_proc}->{state}->{data}->{dirty}->{flag} or !$yml->{run_proc}->{state}->{data}->{dirty}->{flag}) {
		print "[$me] no data to save...nothing dirty - skipping data stow\n" if $trace;
		return 0;
	}
	my $keys = $_dmgr->top_key_primary_keys(topkey => $topkey, trace => $trace);
	my $mainkey = $keys->{primary_key_1};
	my $skey = $keys->{primary_key_2};
	if(!$mainkey or !$skey) {
		warn "[$me] data not populated correctly (data keys missing) - skipping data stow\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	foreach my $grid_key (@grids) {
		if(!exists $yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{$grid_key} or !$yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{$grid_key}) {
			print "[$me] grid [$grid_key] data is not marked dirty -\n" if $trace;
			next;
		}
		
		my $delete_codes = {};
		if($grid_key=~/^grid$/i) {
			foreach  my $c (keys %{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{tempcodes}}) {
				delete $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{tempcodes}->{$c};
			}
		}
		print "[$me] skey[$skey] grid data is dirty - stowing grid[$grid_key]\n" if $trace;

		if(!exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{sentence}) {
			$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{sentence} = $yml_post->{post_parse}->{$mainkey}->{atx_txt}->{sentence_info}->{$skey}->{sentence};
		}
#		if(!exists $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{begin_char_ct}) {
#			$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{begin_char_ct} = $yml->{$mainkey}->{codes}->{sentences}->{$skey}->{begin_char_ct};
#		}
		foreach my $row (keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}}) {
			if($grid_key=~/^grid$/i) {
				my $name_col = 3;
				my $flag_col = 9;
				my $num_col = $name_col - 1;
				my $index = $yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$num_col};
				my $codeval = $yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$name_col};
				my $flag = $yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$flag_col};
				print "[$me] temp stow; skey[$skey] on grid[$grid_key] stowing [$codeval] at index[$index], row[$row] flagval[$flag]\n" if $temp_trace;
				if($flag) {
					$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{tempcodes}->{$index} = $codeval;
					print "  [$me] on grid[$grid_key] adding code [$codeval] to temp stow at index[$index] flagval[$flag]\n" if $temp_trace;
				} else {
					$delete_codes->{$codeval} = 1;
				}
			}
#			foreach my $col (keys %{$yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}}) {
#			if(
			if($grid_key=~/^grid_aspect$/i) {
				my $name_col = 3;
				my $num_col = $name_col - 1;
				my $index = $yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$num_col};
				my $val = $yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$name_col};
				my $ten = 11;
				for(my $i=6; $i<12; $i++) {
					my $rating = $ten - $i;
					if($yml->{run_proc}->{grids}->{$grid_key}->{matrix}->{$row}->{$i}) {
						print "[$me] on grid[$grid_key] stowing [$val] at index[$index], row[$row] icolumnval[$i] rating[$rating]\n" if $trace;
						$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{aspects}->{$val} = $rating;
					}
				}
			}
		}
		if($grid_key=~/^grid$/i) {
			foreach  my $c (keys %{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{codes}}) {
				delete $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{codes}->{$c};
			}
			my $ctr = 1;
			foreach  my $c (keys %{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{tempcodes}}) {
				$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{codes}->{$ctr} = $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{tempcodes}->{$c};
				print "[$me] [$mainkey] temp->re_code store;  grid[$grid_key] skey[$skey] code[".$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{codes}->{$ctr}."] cindex[$c]ctr[$ctr]\n" if $store_trace;
				delete $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{tempcodes}->{$c};
				$ctr++;
			}
			foreach my $code (keys %$delete_codes) {
				foreach  my $c (keys %{$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{codes}}) {
					my $codeval = $yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{codes}->{$c};
					if($code eq $codeval) {
						warn "\n[$me] WARNING! Code [$code] removal failed for {$mainkey} {$skey} under codes\n\n"; 
					}
				}
			}
		}
		$delete_codes = undef;

		$yml->{run_proc}->{grids}->{$grid_key}->{dirty}->{flag} = 0;
		$yml->{run_proc}->{state}->{data}->{dirty}->{flag} = 0;
		$yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{$grid_key} = 0;
	}
	
	$_dmgr->set_topkey_dirty($topkey,1,$trace);
	####
	## this should really be done via the Process Manager...
	####
	$_dmgr->save_yaml_file_data($trace);
	my $mess = "Saved [$skey]";
	$self->add_data_textbox($mess,0);
	
	return 1;
}
sub store_special_data {
	my ($self,$type,$data,$trace) = @_;
	my $me = __PACKAGE__ . " - STORE SPECIAL DATA";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();

	my $topkey = "data_coding";
	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	my $keys = $_dmgr->top_key_primary_keys(topkey => $topkey, trace => $trace);
	my $mainkey = $keys->{primary_key_1};
	my $skey = $keys->{primary_key_2};
	if(!$mainkey or !$skey) {
		warn "[$me] sentence data not populated correctly (data keys missing) - skipping data stow\n";
		#die "\tdying to fix [$me]\n";
		return undef;
	}
	
	if($type=~/^causality/i) {
		$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{causality} = $data->{causality};
	}
	if($type=~/^view_orient/i) {
		$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{view}->{orientation} = $data->{orient};
	}
	if($type=~/^view_level/i) {
		$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{view}->{level} = $data->{level};
	}
	if($type=~/^role_primary/i) {
		$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{primary} = $data->{primary};
	}
	if($type=~/^role_subrole/i) {
		$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{role}->{subrole} = $data->{subrole};
	}
	if($type=~/^new_topic/i) {
		$yml->{$mainkey}->{re_codes}->{sentences}->{$skey}->{override}->{topic} = $data->{topic};
	}
	$data = undef;
	return 1;
}
sub load_selectable_codes {
	my ($self, $trace) = @_;
	my $me = __PACKAGE__ . " LOAD SELECTABLE CODES";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();

	my $grid_key = 'grid_hot_codes';
	if($grid_key=~/^grid_hot_codes$/i) {
		$self->load_hot_codes($grid_key, $trace);
	}
	$grid_key = 'grid_codes';
	if($grid_key=~/^grid_codes$/i) {
		$self->load_all_codes($grid_key, $trace);
	}
	return 1;
}
sub load_all_codes {
	my ($self, $gridkey, $trace) = @_;
	my $me = __PACKAGE__ . " LOAD ALL CODES";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	my $grids = $wxframe->getWxGridsforFrame();
	if(!$gridkey) {
		$gridkey = 'grid_codes';
	}
	my $topkey = "coding_analysis";
	my $matrix = {};
	my $grid = $grids->{$gridkey};
	my $yml_anal = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	my $topkey2 = "data_coding";
	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey2,$trace);

	if($gridkey=~/^grid_codes$/i) {
		print "[$me] yml data, size[".scalar(keys %$yml)."] codes size[".scalar(keys %{$yml_anal->{by_code}->{code_totals}})."]\n" if $trace;
		my $y = $yml_anal->{by_code}->{code_totals};
		my $y2 = $yml->{runlinks}->{add_codes};
		foreach my $cc (keys %$y2) {
			$y->{$cc} = $y2->{$cc};
		}
		my $col = 3;
		my $row = 1;
		my $ctr = 1;
		foreach my $code (sort {$a cmp $b} keys %$y) {
			my $num_col = $col - 1;
			$matrix->{$row}->{$num_col} = $ctr;
			$matrix->{$row}->{$col} = $code;
			my $b_col = $col + 2;
			if($y->{$code}=~/HASH/i) {
				my $bk = $y->{$code}->{blocks};
				$matrix->{$row}->{$b_col} = $bk;
			}
			$row++;
			$ctr++;
		}
	}
	
	if(!defined $matrix and !scalar(keys $matrix)) {
		print "[$me] Warning! This grid[$gridkey] has nothing to load...skipping grid init\n" if $trace;
	}

	my $rctr = 0;
	foreach my $row (keys %$matrix) {
		if($matrix->{$row}=~/HASH/i and scalar(keys %{$matrix->{$row}})) {
			foreach my $col (keys %{$matrix->{$row}}) {
				my $c = $col - 1;
				my $r = $row - 1;
				$grid->SetCellValue($r, $c, $matrix->{$row}->{$col});
				$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(255,255,128));
			}
		}
		$rctr++;
	}
	print "[$me] Loaded grid[$gridkey] with [$rctr] rows of codes\n" if $trace;

	return 1;
}
sub load_hot_codes {
	my ($self, $gridkey, $trace) = @_;
	my $me = __PACKAGE__ . " LOAD HOT CODES";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	my $grids = $wxframe->getWxGridsforFrame();

	if(!$gridkey) {
		$gridkey = 'grid_hot_codes';
	}
	my $topkey = 'data_coding';
	my $matrix = {};
	my $grid = $grids->{$gridkey};

	if($gridkey=~/^grid_hot_codes$/i) {
		my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
		print "[$me] yml data, size[".scalar(keys %$yml)."] codes size[".scalar(keys %{$yml->{runlinks}->{hot_codes}})."]\n" if $trace;
		my $y = $yml->{runlinks}->{hot_codes};
		my $col = 3;
		my $row = 1;
		my $ctr = 1;
		foreach my $code (sort {$y->{$b} <=> $y->{$a}} keys %$y) {
			my $num_col = $col - 1;
			$matrix->{$row}->{$num_col} = $ctr;
			$matrix->{$row}->{$col} = $code;
			my $block_col = $col + 1;
			$matrix->{$row}->{$block_col} = $y->{$code};
			$row++;
			$ctr++;
		}
	}

	if(!defined $matrix and !scalar(keys $matrix)) {
		print "[$me] Warning! This grid[$gridkey] has nothing to load...skipping grid init\n" if $trace;
	}

	my $rctr = 0;
	foreach my $row (keys %$matrix) {
		if($matrix->{$row}=~/HASH/i and scalar(keys %{$matrix->{$row}})) {
			foreach my $col (keys %{$matrix->{$row}}) {
				my $c = $col - 1;
				my $r = $row - 1;
				$grid->SetCellValue($r, $c, $matrix->{$row}->{$col});
				$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(255,255,128));
			}
		}
		$rctr++;
	}
	print "[$me] Loaded grid[$gridkey] with [$rctr] rows of codes\n" if $trace;

	return 1;
}
sub clear_hot_codes {
	my ($self, $trace) = @_;
	my $me = __PACKAGE__ . " CLEAR HOT CODES";
	my $wxframe = $self->{WXFRAME_PTR};
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	my $grids = $wxframe->getWxGridsforFrame();

	my $topkey = 'data_coding';
	my $gridkey = 'grid_hot_codes';
	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	print "[$me] yml data, size[".scalar(keys %$yml)."] codes size[".scalar(keys %{$yml->{runlinks}->{hot_codes}})."]\n" if $trace;
	my $row_ct = scalar(keys %{$yml->{runlinks}->{hot_codes}});

	my $grid = $grids->{$gridkey};
	my $y = $yml->{runlinks}->{hot_codes};
	for (my $r=0; $r<$row_ct; $r++) {
		my $code_col = 2;
		my $ct_col = 1;
		$grid->SetCellValue($r, $ct_col, '');
		$grid->SetCellValue($r, $code_col, '');
##		$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new(255,255,128));
	}
	return 1;
}
sub grid_left_click_event {
	my $layout_ptr = undef;
	my $grid = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' - GRID LEFT CLICK EVENT';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$grid,$event) = @_;
	} else {
		($grid,$event) = @_;
	}
	if(!defined $grid) {
		warn "[$me] ERROR the grid object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $wxframe = $layout_ptr->{WXFRAME_PTR};
#	print "[$me] l_ptr[$layout_ptr] winframe[$winframe] wxframe[$wxframe]\n";
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	my $frame_key = $wxframe->wxframe_key_value();
	my $_pmgr = $layout_ptr->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
#	my $_smgr = $_pmgr->_stateManager();
	my $grids = $_wfmgr->grids_by_wxframe($frame_key);
	my $gids = $layout_ptr->{ROW_KEYED_GRID_IDS};
	my $gid_base = $layout_ptr->{ROW_GRID_ID_COUNT_BASE};
	my $trace = 1;
	my $carp = 1;
	my $dcarp = 0;
	my $step_carp = 1;
	my $inputfield_deduct = 10;

	print "  [$me] l_ptr[$layout_ptr] grid[$grid] event[$event]\n" if $step_carp;
	my $t = $event->GetEventType();
	my $this_id = $event->GetId();
	print "  [$me] event, obj[".$event->GetEventObject()."] type[$t] id[$this_id]\n" if $step_carp;

	if($event->GetEventType() == 10224) {
		my( $c, $r ) = ( $event->GetCol, $event->GetRow );
		my $gridkey = $wxframe->getWxGridKeyByIDforFrame($this_id,$trace);
		print "[$me] gridkey[$gridkey] click location, col[$c] row[$r]\n" if $carp;

		my $topkey = "data_coding";
		my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
		my $keys = $_dmgr->top_key_primary_keys(topkey => $topkey, trace => $trace);
		my $mainkey = $keys->{primary_key_1};
		my $skey = $keys->{primary_key_2};

		if($gridkey=~/^grid_aspect$/i) {
			if($c < 5 or $c > 10) {
				return 1;
			}
			my $state = 1;
			my $val = $grid->GetCellValue($r, $c);
			my $R = 0;
			my $G = 128;
			my $B = 0;
#			my $mainkey = $_dmgr->panel_yaml_data_mainkey('aspectpanel',undef,$trace);

			print "[$me] grid cell ($r, $c) is val[$val]\n" if $trace;
			if(!defined $val) {
				$state = 0;
				print "[$me] grid cell ($r, $c) is not defined - state[$state]\n" if $trace;
			}
			if($val=~/^\d$/ and $val==0) {
				$state = 0;
				print "[$me] grid cell ($r, $c) is zero - state[$state]\n" if $trace;
			}
			if($val eq '') {
				$state = 0;
				print "[$me] grid cell ($r, $c) is blank - state[$state]\n" if $trace;
			}
			my $new_state = 1;
			if($state) {
				$new_state = 0;
				$R = 255;
				$G = 255;
				$B = 144;
				$grid->SetCellValue($r, $c, $new_state);
				my $row = $r + 1;
				my $col = $c + 1;
				$yml->{run_proc}->{grids}->{$gridkey}->{matrix}->{$row}->{$col} = $new_state;
				$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new($R, $G, $B));
			} else {
				my $row = $r + 1;
				my $col = $c + 1;
				$yml->{run_proc}->{grids}->{$gridkey}->{matrix}->{$row}->{$col} = $new_state;
				$grid->SetCellValue($r, $c, $new_state);
				$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new($R, $G, $B));
				for(my $i=5; $i<11; $i++) {
					if($i==$c) {
						next;
					}
					my $val_chk = $grid->GetCellValue($r, $i);
					$new_state = 0;
					$R = 255;
					$G = 255;
					$B = 144;
					if($val_chk) {
						#my $row = $r + 1;
						$col = $i + 1;
						$yml->{run_proc}->{grids}->{$gridkey}->{matrix}->{$row}->{$col} = $new_state;
						$grid->SetCellValue($r, $i, $new_state);
						$grid->SetCellBackgroundColour($r, $i, Wx::Colour->new($R, $G, $B));
					}
				}
			}
#			print "[$me] gridkey[$gridkey][$yml][".$yml->{run_proc}->{grids}."][".$yml->{run_proc}->{grids}->{$gridkey}."][".$yml->{run_proc}->{grids}->{$gridkey}->{dirty}."]\n";
# if(!exists $yml->{run_proc}->{state}->{data}->{dirty}->{flag} or 
#           !$yml->{run_proc}->{state}->{data}->{dirty}->{flag}) {
			$yml->{run_proc}->{grids}->{$gridkey}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{$gridkey} = 1;
		}
		if($gridkey=~/^grid$/i) {
#			my $mainkey = $_dmgr->panel_yaml_data_mainkey('gridpanel',undef,$trace);
			if($c < 5 or $c > 10) {
				return 1;
			}
#			for (my $i=0; $i<14; $i++) {
#				print "[$me] row[$r] col[$i] val[".$grid->GetCellValue($r, $i)."]\n";
#			}

			####
			## on-click, swap cell value 'state'
			## if blank or zero, set to 1
			## if 1, set to 0
			## - set grid to dirty once done
			####
			my $state = 1;
			my $val = $grid->GetCellValue($r, $c);
			my $R = 0;
			my $G = 128;
			my $B = 0;

			print "[$me] mainkey[$mainkey] grid cell ($r, $c) is val[$val]\n" if $trace;
			if(!defined $val) {
				$state = 0;
				print "[$me] grid cell ($r, $c) is not defined - state[$state]\n" if $trace;
			}
			if($val=~/^\d$/ and $val==0) {
				$state = 0;
				print "[$me] grid cell ($r, $c) is zero - state[$state]\n" if $trace;
			}
			if($val eq '') {
				$state = 0;
				print "[$me] grid cell ($r, $c) is blank - state[$state]\n" if $trace;
			}
			my $new_state = 1;
			my $row = $r + 1;
			my $col = $c + 1;
			if($state) {
				$new_state = 0;
				$R = 255;
				$G = 255;
				$B = 144;
			}
			$grid->SetCellValue($r, $c, $new_state);
			print "[$me] NEW cell value, r[$r] c[$c] val[".$grid->GetCellValue($r, $c)."]\n";
			$grid->SetCellBackgroundColour($r, $c, Wx::Colour->new($R, $G, $B));
			$yml->{run_proc}->{grids}->{$gridkey}->{matrix}->{$row}->{$col} = $new_state;

			$yml->{run_proc}->{grids}->{$gridkey}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{$gridkey} = 1;
			$layout_ptr->set_re_state_field(0);
			
		}
#		my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
#			print "[".__PACKAGE__." - $me] yml data, size[".scalar(keys %$yml)."] runlinks size[".scalar(keys %{$yml->{runlinks}})."] aspects size[".scalar(keys %{$yml->{runlinks}->{aspects}})."]\n" if $trace;
		return 1;
	}
	$event->Skip();
	return;
}
sub grid_select_cell_event {
	my $layout_ptr = undef;
	my $grid = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' - GRID SELECT CELL EVENT';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$grid,$event) = @_;
	} else {
		($grid,$event) = @_;
	}
	if(!defined $grid) {
		warn "[$me] ERROR the grid object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $wxframe = $layout_ptr->{WXFRAME_PTR};
#	print "[$me] l_ptr[$layout_ptr] winframe[$winframe] wxframe[$wxframe]\n";
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	my $frame_key = $wxframe->wxframe_key_value();
	my $trace = 1;
	my $carp = 1;
	my $step_carp = 1;

	print "  [$me] l_ptr[$layout_ptr] grid[$grid] event[$event]\n" if $step_carp;
	my $t = $event->GetEventType();
	my $this_id = $event->GetId();
	print "  [$me] event, obj[".$event->GetEventObject()."] type[$t] id[$this_id]\n" if $step_carp;

	if($event->GetEventType() == 10238) {
		my( $c, $r ) = ( $event->GetCol, $event->GetRow );
		my $gridkey = $wxframe->getWxGridKeyByIDforFrame($this_id,$trace);
#		my $editor = $grid->GetCellEditor($r,$c);
#		$editor->Show(1);
		if($c==3) {
			$grid->SetCellEditor($r,$c, Wx::DemoModules::wxGridCER::CustomEditor->new);
		}
		$layout_ptr->{EDIT_FLAG} = 1;
#		$event->Skip();
		print "[$me] gridkey[$gridkey] click location, col[$c] row[$r]\n" if $carp;
	}
}
sub grid_left_double_click_event {
	my $layout_ptr = undef;
	my $grid = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' - GRID LEFT DOUBLE CLICK EVENT';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$grid,$event) = @_;
	} else {
		($grid,$event) = @_;
	}
	if(!defined $grid) {
		warn "[$me] ERROR the grid object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $wxframe = $layout_ptr->{WXFRAME_PTR};
#	print "[$me] l_ptr[$layout_ptr] winframe[$winframe] wxframe[$wxframe]\n";
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	my $frame_key = $wxframe->wxframe_key_value();
	my $_pmgr = $layout_ptr->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
#	my $_smgr = $_pmgr->_stateManager();
	my $grids = $_wfmgr->grids_by_wxframe($frame_key);
	my $gids = $layout_ptr->{ROW_KEYED_GRID_IDS};
	my $gid_base = $layout_ptr->{ROW_GRID_ID_COUNT_BASE};
	my $trace = 1;
	my $carp = 1;
	my $dcarp = 0;
	my $step_carp = 1;
	my $inputfield_deduct = 10;

	print "  [$me] l_ptr[$layout_ptr] grid[$grid] event[$event]\n" if $step_carp;
	my $t = $event->GetEventType();
	my $this_id = $event->GetId();
	my $evt_obj = $event->GetEventObject();
	print "  [$me] event, obj[".$event->GetEventObject()."] type[$t] id[$this_id]\n" if $step_carp;

	if($event->GetEventType() == 10226) {
		my( $c, $r ) = ( $event->GetCol, $event->GetRow );
#		my $action_num = $evt_obj->GetLabel();
		my $gridkey = $wxframe->getWxGridKeyByIDforFrame($this_id,$trace);
		print "[$me] gridkey[$gridkey] click location, col[$c] row[$r]\n" if $trace;

		if($c!=0) {
			print "[$me] gridkey[$gridkey] click location is not first col[$c]...skipping\n" if $trace;
			return 1;
		}
		
		my $grids = $wxframe->getWxGridsforFrame();
		my $topkey = "data_coding";
		my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
		if($gridkey=~/^grid_codes$/i) {
			my $move_grid_key = 'grid';
			my $move_grid = $grids->{$move_grid_key};
			my $mainkey = $_dmgr->panel_yaml_data_mainkey('gridpanel',undef,$trace);

			my $name_col = 3;
			my $num_col = $name_col - 1;
			my $d_name_col = $name_col - 1;
			my $d_num_col = $num_col - 1;
			my $numval = $grid->GetCellValue($r, $d_num_col);
			my $nameval = $grid->GetCellValue($r, $d_name_col);
			print "[$me] mainkey[$mainkey] gridkey[$gridkey] row[$r] click num[$numval] code[$nameval]\n" if $trace;
#			if($c < 5 or $c > 10) {
#				return 1;
#			}
			my $this_col = 9;
			my $d_this_col = $this_col - 1;
			my $scodes_size = scalar(keys %{$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}});
			my $new_row_index = $scodes_size + 1;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$num_col} = $scodes_size + 1;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$name_col} = $nameval;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$this_col} = 1;
			$move_grid->SetCellValue($scodes_size, $d_num_col, $new_row_index);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_num_col, Wx::Colour->new(255,255,128));
			$move_grid->SetCellValue($scodes_size, $d_name_col, $nameval);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_name_col, Wx::Colour->new(255,255,128));
			$move_grid->SetCellValue($scodes_size, $d_this_col, 1);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_this_col, Wx::Colour->new(0,255,19));

#			my $y_hot = $yml->{runlinks}->{hot_codes};
			my $ct = 0;
			if(exists $yml->{runlinks}->{hot_codes}->{$nameval}) {
				$ct = $yml->{runlinks}->{hot_codes}->{$nameval};
			}
			$ct++;
			$yml->{runlinks}->{hot_codes}->{$nameval} = $ct;
			$layout_ptr->clear_hot_codes($trace);
			$layout_ptr->load_hot_codes(undef, $trace);

			$yml->{run_proc}->{grids}->{$move_grid_key}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{$move_grid_key} = 1;
			print "[$me] move to gridkey[$move_grid_key] code ct in matrix[$scodes_size] code[$nameval]\n" if $trace;
			$layout_ptr->set_re_state_field(0);
		}

	}
	$event->Skip();
	return;
}
sub hot_grid_left_double_click_event {
	my $layout_ptr = undef;
	my $grid = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' HOT GRID LEFT DOUBLE CLICK EVENT';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$grid,$event) = @_;
	} else {
		($grid,$event) = @_;
	}
	if(!defined $grid) {
		warn "[$me] ERROR the grid object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $wxframe = $layout_ptr->{WXFRAME_PTR};
#	print "[$me] l_ptr[$layout_ptr] winframe[$winframe] wxframe[$wxframe]\n";
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	my $frame_key = $wxframe->wxframe_key_value();
	my $_pmgr = $layout_ptr->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
#	my $_smgr = $_pmgr->_stateManager();
	my $grids = $_wfmgr->grids_by_wxframe($frame_key);
	my $gids = $layout_ptr->{ROW_KEYED_GRID_IDS};
	my $gid_base = $layout_ptr->{ROW_GRID_ID_COUNT_BASE};
	my $trace = 1;
	my $carp = 1;
	my $dcarp = 0;
	my $step_carp = 1;
	my $inputfield_deduct = 10;

	print "  [$me] l_ptr[$layout_ptr] grid[$grid] event[$event]\n" if $step_carp;
	my $t = $event->GetEventType();
	my $this_id = $event->GetId();
	my $evt_obj = $event->GetEventObject();
	print "  [$me] event, obj[".$event->GetEventObject()."] type[$t] id[$this_id]\n" if $step_carp;

	if($event->GetEventType() == 10226) {
		my( $c, $r ) = ( $event->GetCol, $event->GetRow );
#		my $action_num = $evt_obj->GetLabel();
		my $gridkey = $wxframe->getWxGridKeyByIDforFrame($this_id,$trace);
		print "[$me] gridkey[$gridkey] click location, col[$c] row[$r]\n" if $trace;

		if($c!=0) {
			print "[$me] gridkey[$gridkey] click location is not first col[$c]...skipping\n" if $trace;
			return 1;
		}
		
		my $grids = $wxframe->getWxGridsforFrame();
		my $topkey = "data_coding";
		my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
		if($gridkey=~/^grid_codes$/i) {
			my $move_grid_key = 'grid';
			my $move_grid = $grids->{$move_grid_key};
			my $mainkey = $_dmgr->panel_yaml_data_mainkey('gridpanel',undef,$trace);

			my $name_col = 3;
			my $num_col = $name_col - 1;
			my $d_name_col = $name_col - 1;
			my $d_num_col = $num_col - 1;
			my $numval = $grid->GetCellValue($r, $d_num_col);
			my $nameval = $grid->GetCellValue($r, $d_name_col);
			print "[$me] mainkey[$mainkey] gridkey[$gridkey] row[$r] click num[$numval] code[$nameval]\n" if $trace;
#			if($c < 5 or $c > 10) {
#				return 1;
#			}
			my $this_col = 9;
			my $d_this_col = $this_col - 1;
			my $scodes_size = scalar(keys %{$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}});
			my $new_row_index = $scodes_size + 1;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$num_col} = $scodes_size + 1;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$name_col} = $nameval;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$this_col} = 1;
			$move_grid->SetCellValue($scodes_size, $d_num_col, $new_row_index);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_num_col, Wx::Colour->new(255,255,128));
			$move_grid->SetCellValue($scodes_size, $d_name_col, $nameval);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_name_col, Wx::Colour->new(255,255,128));
			$move_grid->SetCellValue($scodes_size, $d_this_col, 1);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_this_col, Wx::Colour->new(0,255,19));

			$yml->{run_proc}->{grids}->{$move_grid_key}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{$move_grid_key} = 1;
			print "[$me] move to gridkey[$move_grid_key] code ct in matrix[$scodes_size] code[$nameval]\n" if $trace;
		}

	}
	return;
}
sub hot_grid_left_click_event {
	my $layout_ptr = undef;
	my $grid = undef;
	my $event = undef;
	my $me = __PACKAGE__ . ' HOT GRID LEFT CLICK EVENT';
	print "[$me] arg size [".scalar(@_)."]\n";
	if(scalar(@_) > 2) {
		($layout_ptr,$grid,$event) = @_;
	} else {
		($grid,$event) = @_;
	}
	if(!defined $grid) {
		warn "[$me] ERROR the grid object is missing!\n";
		die "\tdying to fix [$me]\n";
		return undef;
	}
	my $wxframe = $layout_ptr->{WXFRAME_PTR};
#	print "[$me] l_ptr[$layout_ptr] winframe[$winframe] wxframe[$wxframe]\n";
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	my $frame_key = $wxframe->wxframe_key_value();
	my $_pmgr = $layout_ptr->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	my $grids = $_wfmgr->grids_by_wxframe($frame_key);
	my $gids = $layout_ptr->{ROW_KEYED_GRID_IDS};
	my $gid_base = $layout_ptr->{ROW_GRID_ID_COUNT_BASE};
	my $trace = 1;
	my $carp = 1;
	my $dcarp = 0;
	my $step_carp = 1;
	my $inputfield_deduct = 10;

	print "  [$me] l_ptr[$layout_ptr] grid[$grid] event[$event]\n" if $step_carp;
	my $t = $event->GetEventType();
	my $this_id = $event->GetId();
	print "  [$me] event, obj[".$event->GetEventObject()."] type[$t] id[$this_id]\n" if $step_carp;

	if($event->GetEventType() == 10224) {
		my( $c, $r ) = ( $event->GetCol, $event->GetRow );
		my $gridkey = $wxframe->getWxGridKeyByIDforFrame($this_id,$trace);
		print "[$me] gridkey[$gridkey] click location, col[$c] row[$r]\n" if $carp;

		if($c) {
			print "  [$me] column value > 0 (first col)...ignoring row mark try\n" if $step_carp;
			$event->Skip();
			return 1;
		}
		
		my $grids = $wxframe->getWxGridsforFrame();
		my $topkey = "data_coding";
		my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
		if($gridkey=~/^grid_hot_codes$/i) {

			my $move_grid_key = 'grid';
			my $move_grid = $grids->{$move_grid_key};
			my $mainkey = $_dmgr->panel_yaml_data_mainkey('gridpanel',undef,$trace);

			my $name_col = 3;
			my $num_col = $name_col - 1;
			my $d_name_col = $name_col - 1;
			my $d_num_col = $num_col - 1;
			my $numval = $grid->GetCellValue($r, $d_num_col);
			my $nameval = $grid->GetCellValue($r, $d_name_col);
			if(!$numval) {
				print "[$me] !! Warning! Code number value is null, mainkey[$mainkey] gridkey[$gridkey] row[$r] \n" if $trace;
				$event->Skip();
				return 1;
			}
			print "[$me] mainkey[$mainkey] gridkey[$gridkey] row[$r] click num[$numval] code[$nameval]\n" if $trace;
#			print "[$me] mainkey[$mainkey] gridkey[$gridkey] row[$r] click num[$numval] code[$nameval]\n" if $trace;

			my $this_col = 9;
			my $d_this_col = $this_col - 1;
			my $scodes_size = scalar(keys %{$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}});
			my $new_row_index = $scodes_size + 1;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$num_col} = $scodes_size + 1;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$name_col} = $nameval;
			$yml->{run_proc}->{grids}->{$move_grid_key}->{matrix}->{$new_row_index}->{$this_col} = 1;
			$move_grid->SetCellValue($scodes_size, $d_num_col, $new_row_index);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_num_col, Wx::Colour->new(255,255,128));
			$move_grid->SetCellValue($scodes_size, $d_name_col, $nameval);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_name_col, Wx::Colour->new(255,255,128));
			$move_grid->SetCellValue($scodes_size, $d_this_col, 1);
			$move_grid->SetCellBackgroundColour($scodes_size, $d_this_col, Wx::Colour->new(0,255,19));

			my $ct = 0;
			if(exists $yml->{runlinks}->{hot_codes}->{$nameval}) {
				$ct = $yml->{runlinks}->{hot_codes}->{$nameval};
			}
			$ct++;
			$yml->{runlinks}->{hot_codes}->{$nameval} = $ct;
			$layout_ptr->clear_hot_codes($trace);
			$layout_ptr->load_hot_codes(undef, $trace);

			$yml->{run_proc}->{grids}->{$move_grid_key}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{flag} = 1;
			$yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{$move_grid_key} = 1;
			print "[$me] move to gridkey[$move_grid_key] code ct in matrix[$scodes_size] code[$nameval]\n" if $trace;
			
			$layout_ptr->set_re_state_field(0);

		}
#		$event->Skip();
#		return 1;
	}
	$event->Skip();
	return;
}
sub complete_confirm {
	my ($self,$topkey,$trace) = @_;
	my $wxframe = $self->{WXFRAME_PTR};
	my $_pmgr = $self->process_mgr_ptr();
	my $_dmgr = $_pmgr->data_manager();
	my $yml = $_dmgr->get_yaml_data_by_topkey($topkey,$trace);
	$yml->{run_proc}->{state}->{data}->{dirty}->{flag} = 1;
	$yml->{run_proc}->{state}->{data}->{dirty}->{grids}->{grid} = 1;
	$self->store_new_data($trace);
	
	$self->set_re_state_field(1);
	
	return 1;
}
sub set_re_state_field {
	my ($self,$state,$trace) = @_;
	my $wxframe = $self->{WXFRAME_PTR};
	my $panel = 'mainpanel';
	my $field = 'sentence_state';
	my $state_txt = 'Tainted';
	if($state==1) {
		$state_txt = 'Stored';
	}
	if($state==-1) {
		$state_txt = 'Not RE';
	}
	if(exists $wxframe->{$panel}->{$field}) {
		$wxframe->{$panel}->{$field}->SetLabel($state_txt);
	}
	
	return 1;
}
sub add_data_textbox {
	my ($self,$text,$has_LF,$trace) = @_;
	my $wxframe = $self->{WXFRAME_PTR};
	my $panel = 'mainpanel';
	my $textbox = 'textboxright';
	
	if(!exists $wxframe->{$textbox}) {
		warn "textbox [$textbox] does not exist\n";
		return undef;
	}
	$wxframe->{$textbox}->SetInsertionPoint(0);
	if($has_LF) {
		$wxframe->{$textbox}->WriteText("$text");
	} else {
		$wxframe->{$textbox}->WriteText("$text\n");
	}
	return 1;
}
sub handle_signal_update {
	my $self = shift;
	my (%pms) = @_;
	if(!exists $pms{sigkey}) {
		warn "bad\n";
		die "\tdying to fix...\n";
		return undef;
	}
	my $me = 'SIGNAL UPDATE';
	my $carp = 1;
	my $sigkey = $pms{sigkey};
	my $status = 0;
	my $count_label_text = '0000';
	if(exists $pms{status}) {
		$status = $pms{status};
	}
	if(exists $pms{message} and $pms{message}) {
		$count_label_text = $pms{message};
	}
	my $more_data_href = undef;
	if(exists $pms{more_info} and $pms{more_info}=~/HASH/i) {
		$more_data_href = $pms{more_info};
		if(exists $more_data_href->{count} and $more_data_href->{count}) {
			$count_label_text = $more_data_href->{count};
		}
	}
	my $wxframe = $self->{WXFRAME_PTR};
#	my $_wfmgr = $wxframe->_wfmgr_handle();
	my $_wfmgr = $self->wxframe_mgr_ptr();
#	my $_pmgr = $self->process_mgr_ptr();
#	my $_dmgr = $_pmgr->data_manager();
#	my $_smgr = $_pmgr->state_manager();
	my $mainclient = $_screen_input_client_name;
	my $sigval = 1; ##...hardwired!
	my $cntrl_id = $_wfmgr->get_cntrl_id_sigkey_sigval($sigkey,$sigval);
#	my $cntrl_id = $_wfmgr->get_cntrl_id_sigkey_sigval($sigkey,$sigval);
	print "[$me] cntrl id[$cntrl_id] for sigkey[$sigkey] sigval[$sigval]\n" if $carp;

	$_wfmgr->load_data_pack_monitor(client => $mainclient, wxframe => $wxframe);
	if($_reader_clients->{$sigkey}=~/^reader_1/i) {
		print "!!!!!!!!!!11 reader 1 is updating!!!!!!!!!!!!!1\n";
#		$_wfmgr->load_data_pack_lasttracker(client => $_reader_clients->{$sigkey}, wxframe => $wxframe);
	}
	if($_reader_clients->{$sigkey}=~/^reader_2/i) {
#		print "!!!!!!!!!!11 reader 2 is updating!!!!!!!!!!!!!1\n";
		$_wfmgr->load_data_pack_lasttracker(client => $_reader_clients->{$sigkey}, wxframe => $wxframe);
	}
	print "[$me] cntrl id[$cntrl_id] for sigkey[$sigkey] sigval[$sigval]\n" if $carp;
	$self->update_reader_count(btnid => $cntrl_id, reader_count => $count_label_text); 
	if($_push_data_fwd) {
		my $try = 0;
		my $sig = 'push_go';
		my $val = 1;
		if($_wfmgr) {
			$try = $_wfmgr->signal_an_event(carp => $carp, sigkey => 'push_go', sigvalue => 1);
		}
		if(!$try) {
			$wxframe->push_new_signal( $sig, $val );
		}
	}

	return 1;
}
sub handle_button_change {
	my $self = shift;
	my $trace = 0;
	my (%pms) = @_;
	my $me = 'HANDLE BUTTON CHANGE';
	if(exists $pms{trace}) {
		$trace = $pms{trace};
	}
	if(!exists $pms{sigkey}) {
		warn "[$me] bad sigkey!\n";
		die "\tdying to fix...\n";
		return undef;
	}
	my $sigkey = $pms{sigkey};
	my $state = 0;
	my $text = 'no text in message';
	if(exists $pms{switch_state}) {
		$state = $pms{switch_state};
	}
	if(exists $pms{text}) {
		$text = $pms{text};
	}
	my $has_LF = 0;
	if(exists $pms{has_lf} and $pms{has_lf}) {
		$has_LF = 1;
	}

	print "{TRACE}[$me] in: state[$state] sigkey[$sigkey] text[$text]\n" if $trace;
	my $wxframe = $self->{WXFRAME_PTR};
#	my $_wfmgr = $wxframe->_wfmgr_handle();
#	my $_pmgr = $wxframe->_pmgr_handle();
	my $_wfmgr = $self->wxframe_mgr_ptr();
	my $_pmgr = $self->process_mgr_ptr();
#	my $_dmgr = $_pmgr->data_manager();
#	my $_smgr = $_pmgr->state_manager();
	my $wxpoe_config = $_pmgr->session_wxframe_tasking_WxPoeIO();
	
	my $sigval = 1; ##...hardwired!
	my $cntrl_id = $_wfmgr->get_cntrl_id_sigkey_sigval($sigkey,$sigval);
	print "{TRACE}[$me] state[$state] cntrl id[$cntrl_id] for sigkey[$sigkey] sigval[$sigval]\n" if $trace;

	my $sswap = undef;
	my $sig_href = undef;
	my $sigvalue = 0;
	if($sswap = $_wfmgr->control_signal_swap_states($cntrl_id)) {
		if($sswap > 0) {
			$sigvalue = $_wfmgr->get_primary_sigvalue_by_cntrl_id($cntrl_id);
		}
		if($sswap < 0) {
			$sigvalue = $_wfmgr->get_secondary_sigvalue_by_cntrl_id($cntrl_id);
		}
	}

	my $key_href = $_wfmgr->gui_ref_ids_panel_n_ctrls($cntrl_id);
	if(!exists $key_href->{panel} or !$key_href->{panel}) {
		warn "[$me] Error! Missing panel value for btn id[$cntrl_id]\n";
		die "\tdying to fix [$me]...\n";
		return undef;
	}
	my $panel = $key_href->{panel};
	if(!exists $key_href->{cname} or !$key_href->{cname}) {
		warn "[$me] Error! Missing name value for btn id[$cntrl_id] on panel[$panel]\n";
		die "\tdying to fix [$me]...\n";
		return undef;
	}
	my $cname = $key_href->{cname};
	my $swap_label = undef;
	if(exists $wxpoe_config->{wp_signal_keys}->{$sigkey}->{sigvalues}->{$sigvalue}->{button_label_swap} and $wxpoe_config->{wp_signal_keys}->{$sigkey}->{sigvalues}->{$sigvalue}->{button_label_swap}) {
		$swap_label = $wxpoe_config->{wp_signal_keys}->{$sigkey}->{sigvalues}->{$sigvalue}->{button_label_swap};
	}

	print "{TRACE}[$me] state[$state] panel[$panel] cname[$cname] cntrl id[$cntrl_id] swap[$swap_label] for sigkey[$sigkey] sigval[$sigval]\n" if $trace;
	$wxframe->{$cname}->SetLabel($swap_label);

	return 1;
}
sub handle_button_switch {
	my $self = shift;
	my $trace = 0;
	my (%pms) = @_;
	my $me = 'HANDLE BUTTON SWITCH';
	if(exists $pms{trace}) {
		$trace = $pms{trace};
	}
	if(!exists $pms{src_sigkey}) {
		warn "[$me] bad sigkey!\n";
		die "\tdying to fix...\n";
		return undef;
	}
	my $sigkey = $pms{src_sigkey};
	my $state = 0;
	my $text = 'no text in message';
	if(exists $pms{switch_state}) {
		$state = $pms{switch_state};
	}
	my $sigval = 0;

	print "{TRACE}[$me] in: state[$state] sigkey[$sigkey] text[$text]\n" if $trace;
	my $wxframe = $self->wxframe_handle();

	my $cntrl_id = $wxframe->getCntrlIDSsigkeyDefSigval($sigkey,$sigval);
	print "{TRACE}[$me] state[$state] cntrl id[$cntrl_id] for sigkey[$sigkey] sigval[$sigval]\n" if $trace;

	my $sig_href = undef;
	my $sigvalue = 0;
	my $sswap = $wxframe->controlSignalSwapState($cntrl_id);
	if($sswap) {
		if($sswap > 0) {
			$sigvalue = $wxframe->getPrimarySigvalueByControlID($cntrl_id);
		}
		if($sswap < 0) {
			$sigvalue = $wxframe->getSecondarySigvalueByControlID($cntrl_id);
		}
	}
	my $panel = $self->get_panel_name_by_cntrl_id($cntrl_id);
	my $cname = $self->get_field_name_by_cntrl_id($cntrl_id);
	
	$wxframe->controlSignalSwapState($cntrl_id,1);

	my $swap = $self->get_swap_label_for_signal($sigkey,$sigvalue,$cname,$trace);

	print "{TRACE}[$me] state[$state] panel[$panel] cname[$cname] cntrl id[$cntrl_id] swap[$swap] for sigkey[$sigkey] sigval[$sigval]\n" if $trace;

	$wxframe->{$cname}->SetLabel($swap);

	return 1;
}
sub timer_control {
	#sigkey => $sigkey, integer => $intgr, text => $text, trace => $trace);
	my $self = shift;
	my $me = __PACKAGE__ . " TIMER CONTROL";
	my $wxframe = $self->{WXFRAME_PTR};
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	my $trace = $self->{TRACE_STD_MESSAGING};
	$trace = 1;
	my (%pms) = @_;
	if(exists $pms{trace}) {
		$trace = $pms{trace};
	}
	if(!exists $pms{sigkey}) {
		warn "[$me] bad sigkey\n";
		die "\tdying to fix [$me]...\n";
		return undef;
	}
	my $sigkey = $pms{sigkey};
	my $signal_keyed = $sigkey . "__s__00";
	if(exists $pms{sigvalue}) {
		$signal_keyed = $sigkey . "__s__" . $pms{sigvalue};
	}
	my $sm = $self->{TIMER_CNAME_KEY_MAP};
	my $on_off_state = 0;
	my $cname = undef;
	if(!exists $pms{cname}) {
		if(exists $sm->{$signal_keyed} and $sm->{$signal_keyed}) {
			$cname = $sm->{$signal_keyed};
		}
	} else {
		$cname = $pms{cname};
		$on_off_state = 1;
		if(exists $pms{on_off}) {
			$on_off_state = $pms{on_off};
		}
	}
	if(!defined $cname) {
		warn "[$me] bad cname...must have to continue\n";
		die "\tdying to fix [$me]...\n";
		return undef;
	}
	if($on_off_state) {
		if(!exists $sm->{$signal_keyed}) {
			$sm->{$signal_keyed} = $cname;
		}
	}
	if(exists $pms{csstate}) { ## client signal state, default == 1
		$on_off_state = $pms{csstate};
	}
	
	####
	## this timer control is rudimentary
	## there is only one timer field 'time_diff', so only one control can use it at a time
	## would need some type of "timer lock" in order to have multiple choices in timer display...
	####
	my $field = 'time_diff';
	my $hms = $_wfmgr->hms_delta_from_timer_start($field,$on_off_state,$trace);
	if($on_off_state) {
		$self->{TIMER_ON} = 1;
	} else {
		$self->{TIMER_ON} = -1;
	}

	return 1;

	my $text = undef;
	my $status = 0;
	if(exists $pms{text}) {
		$text = $pms{text};
	}
	if(exists $pms{estatus}) { ## error status
		$status = $pms{estatus};
	}

	return 1;
}

sub update_reader_count { 
	my $self = shift;
	my (%pms) = @_;
	my $me = 'UPDATE READER COUNT';
	if(!exists $pms{btnid} or !$pms{btnid}) {
		warn "[$me] bad button id!\n";
		die "\tdying to fix [$me]...\n";
		return undef;
	}
	my $cntrl_id = $pms{btnid};
	my $count_label_text = '0000';
	if(exists $pms{reader_count} and $pms{reader_count}=~/^\d+$/) {
		$count_label_text = $pms{reader_count};
		my $ct = $count_label_text = $count_label_text * 1;
		if($ct < 1000) {
			$count_label_text = "0" . $count_label_text;
		}
		if($ct < 100) {
			$count_label_text = "0" . $count_label_text;
		}
		if($ct < 10) {
			$count_label_text = "0" . $count_label_text;
		}
	}
	my $wxframe = $self->{WXFRAME_PTR};
#	my $_wfmgr = $wxframe->_wfmgr_handle();
	my $_wfmgr = $self->wxframe_mgr_ptr();
#	my $_pmgr = $self->process_mgr_ptr();
#	my $_dmgr = $_pmgr->data_manager();
#	my $_smgr = $_pmgr->state_manager();

	my $key_href = $_wfmgr->gui_ref_ids_panel_n_ctrls($cntrl_id);
	if(!exists $key_href->{panel} or !$key_href->{panel}) {
		warn "[$me] Error! Missing panel value for btn id[$cntrl_id]\n";
		die "\tdying to fix [$me]...\n";
		return undef;
	}
	my $panel = $key_href->{panel};
	if(!exists $key_href->{cname} or !$key_href->{cname}) {
		warn "[$me] Error! Missing name value for btn id[$cntrl_id] on panel[$panel]\n";
		die "\tdying to fix [$me]...\n";
		return undef;
	}
	my $cname = $key_href->{cname};
	my $khash = $_wfmgr->gui_panel_button_text_ctrls_sync3($cname);
	my $push_fld = $khash->{push};

#	print "[$me] panel[$panel] cname[$cname] cntrl id[$cntrl_id] text[$count_label_text]\n";
	$wxframe->{$panel}->{$push_fld}->SetLabel($count_label_text);

	return;
}

1;
