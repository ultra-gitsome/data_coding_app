package DataCoderFrameCon;
#######################################
#
#######################################
#
#   This package overrides Wx::Frame, and allows us to put controls
#   in the frame.
#
#use Moose;
use strict;
use warnings;

use Wx qw(:everything);
 
use vars qw(@ISA);
@ISA = qw(Wx::Frame);
use base 'Wx::Frame';
#@Timing::DataCoding::DataCoderAppCon::ISA = qw(Timing::Monitor);
use POE::Filter::Reference;
  
#
#   most of these appear to be for constant declarations.
#
#use Wx( qw [ wxDefaultSize ] );
use Wx qw(:id
          :toolbar
          :socket
		  :window
		  :button
		  :combobox
          wxNullBitmap
          wxDefaultPosition
          wxDefaultSize
		  wxVERTICAL
		  wxFIXED_MINSIZE
		  wxEXPAND wxALL
          wxNullBitmap
          wxTB_VERTICAL
          wxSIZE
          wxSOCKET_WAITALL
          wxTE_MULTILINE
          wxBITMAP_TYPE_BMP
          wxDP_ALLOWNONE
		  wxDEFAULT_FRAME_STYLE
);

#
#   Wx::Events allows us to attach events to user's actions.
#   EVT_SIZE for resizing a window
#   EVT_MENU for selecting a menu item
#   EVT_COMBOBOX for selecting a combo box item
#   EVT_TOOL_ENTER for selecting toolbar items
#
use Wx::Event qw(EVT_SIZE
                 EVT_MENU
                 EVT_SOCKET_CONNECTION
                 EVT_SOCKET_INPUT
                 EVT_SOCKET_OUTPUT
                 EVT_SOCKET_LOST
                 EVT_IDLE
                 EVT_COMBOBOX
                 EVT_UPDATE_UI
                 EVT_TOOL_ENTER
				 EVT_BUTTON
				 EVT_CLOSE
				EVT_TIMER
				 );
use Wx::Socket qw(:SocketServer
					:SocketBase
					wxSOCKET_WAITALL
					wxSOCKET_NOWAIT
					SetFlags
					);
use Wx::Timer qw(:TimerStart
					:TimerStop
					EVT_TIMER
					);

#use Timing::Monitor::AppCon::WxPoeLayoutDataCoder;
BEGIN { 
	eval { require Timing::DataCoding::AppCon::WxPoeLayoutDataCoder }
		or die "Error: Timing::DataCoding::AppCon::WxPoeLayoutDataCoder not installed: $@";
   import Timing::DataCoding::AppCon::WxPoeLayoutDataCoder;
}

#use Timing::WxDisplay::FrameControlMain;
BEGIN { 
	eval { require Timing::WxDisplay::FrameControlMain }
		or die "Error: Timing::WxDisplay::FrameControlMain not installed: $@";
   import Timing::WxDisplay::FrameControlMain;
}

#extends 'FrameControlMain';
@ISA = qw(FrameControlMain); ## inherits from Main WxPoeApp


my $testing_carp = 1;

#### expected variables...
my $_wxframe_type = 'super2';
my $_wxframe_title = 'CMmonitor';
my $_wxframe_ident = 'mainframe';
my $_wxframe_name_key = 'main';
my $_layout_class = 'WxPoeLayoutDataCoder';
my $_reload_grid_displays = 1;

sub getFrameIdent {
	my $self = shift;
	if(!defined $self->{WXFRAME_IDENT}) {
		$self->{WXFRAME_IDENT} = $_wxframe_ident;
	}
	return $self->{WXFRAME_IDENT};
}
sub getFrameKey {
	my $self = shift;
	return $_wxframe_name_key;
}
sub getFrameType {
	my $self = shift;
	if(!defined $self->{WXFRAME_GUI_TYPE}) {
		if(!$_wxframe_type) {
			warn "[FRAME CONTROL MAIN] ERROR! No layout TYPE found...epic fail.\n";
			die "\tdying to fix [FRAME CONTROL MAIN]...\n";
		}
		$self->{WXFRAME_GUI_TYPE} = $_wxframe_type;
		warn "[FRAME CONTROL MAIN] fetching frame type [$_wxframe_type] for wxframe.\n" if $self->{TESTING_CARP};
	}
	return $self->{WXFRAME_GUI_TYPE};
}
sub frame_title {
	my $self = shift;
	if(!defined $self->{WXFRAME_TITLE}) {
		$self->{WXFRAME_TITLE} = $_wxframe_title;
	}
	return $self->{WXFRAME_TITLE};
}
sub getLayoutClass {
	my $self = shift;
	if(!defined $self->{LAYOUT_CLASS_NAME}) {
		if(!$_layout_class) {
			warn "[FRAME CONTROL MAIN] ERROR! No layout class found...epic fail.\n";
			die "\tdying to fix [FRAME CONTROL MAIN]...\n";
		}
		$self->{LAYOUT_CLASS_NAME} = $_layout_class;
	}
	return $self->{LAYOUT_CLASS_NAME};
}
sub get_frame_key {
	my $self = shift;
	return $_wxframe_name_key;
}
sub get_frame_type {
	my $self = shift;
	if(!defined $self->{WXFRAME_GUI_TYPE}) {
		if(!$_wxframe_type) {
			warn "[FRAME CONTROL MAIN] ERROR! No layout TYPE found...epic fail.\n";
			die "\tdying to fix [FRAME CONTROL MAIN]...\n";
		}
		$self->{WXFRAME_GUI_TYPE} = $_wxframe_type;
		warn "[FRAME CONTROL MAIN] fetching frame type [$_wxframe_type] for wxframe.\n" if $self->{TESTING_CARP};
	}
	return $self->{WXFRAME_GUI_TYPE};
}
sub reload_grid_displays {
	my $self = shift;
	return $_reload_grid_displays;
}

sub send_notice_to_forward_data { 

	my $wxframe = $_[0];
	my $main_app = $wxframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
#	my $_wfmgr = $winframe->_wfmgr_handle();

	my $try = 0;
	my $carp = 1;
	my $sig = 'push_go';
	my $val = 1;
	print "[wxframe - SEND NOTICE - FWD DATA] check signal in; sigkey[$sig] sigval[$val]\n" if $carp;
	if($_wfmgr) {
		$try = $_wfmgr->signal_an_event(carp => $carp, sigkey => 'push_go', sigvalue => 1);
		print "[wxframe - SEND NOTICE - FWD DATA] success on [signal_an_event] ?[$try]; sigkey[$sig] sigval[$val]\n" if $carp;
	}
	if(!$try) {
		print "[wxframe - SEND NOTICE - FWD DATA] no success on [signal_an_event] pushing signal onto queue; sigkey[$sig] sigval[$val]\n" if $carp;
		$wxframe->push_new_signal( $sig, $val );
	}
	return 1;
}


1;
