package DataCoderWxPoe;
#######################################
## The starter app is a shell to start and show the frames
##   inherits from the Main WxPoeApp
##   the frame is initiated via the OnInit() in the Main WxPoeApp
##   the frame specific designations are here
##   see the Main WxPoeApp package for general frame startup methods
#######################################
use strict;
use warnings;

BEGIN { 
	eval { require Timing::DataCoding::DataCoderFrameCon }
		or die "Error: Timing::DataCoding::DataCoderFrameCon not installed: $@";
   import Timing::DataCoding::DataCoderFrameCon;
}

use vars qw(@ISA);
@ISA = qw(Wx::App);
use base 'Wx::App';
@Timing::DataCoding::DataCoderFrameCon::ISA = qw(Timing::DataCoding);

use vars qw(@frames);

#use Timing::WxDisplay::WxPoeAppMain;
BEGIN { 
	eval { require Timing::WxDisplay::WxPoeAppMain }
		or die "Error: Timing::WxDisplay::WxPoeAppMain not installed: $@";
   import Timing::WxDisplay::WxPoeAppMain;
}

@ISA = qw(WxPoeAppMain); ## inherits from Main WxPoeApp

my $testing = 1;

######
######
#my $_wxframe_mgr_obj = undef;

my $_mainframe = 'cmonitor';
my $_mainframeclass = 'DataCoderFrameCon';
my $_more_frames = {'none' => ''};

sub getMainFrameIdent {
	my $self = shift;
	return $_mainframe;
}
sub getMainFrameClass {
	my $self = shift;
	return $_mainframeclass;
}

sub newMainFrame {
    my $self = shift;
	## create frame to hold main display
    my $frame = TSStartFrame->new();
	$frame->Show(1);
	$self->SetTopWindow($frame);
	$frame->Raise();
}
sub newTagTrackFrame {
    my $self = shift;
	## create frame to hold tag tracking display
    my $frame = TSTagTrackerFrame->new();
	$frame->Show(1);
	$self->SetTopWindow($frame);
	$frame->Raise();
}
sub addMoreFrames {
    my $self = shift;
	if(defined $_more_frames and scalar(keys %$_more_frames)) {
		foreach my $ident (keys %$_more_frames) {
			## create frame to hold next display
			my $_class = $_more_frames->{$ident};
			my $frame = $_class->new();
			$frame->Show(1);
			$self->SetTopWindow($frame);
			$frame->Raise();
		}
	}
}

## module end
#no Moose;
1

