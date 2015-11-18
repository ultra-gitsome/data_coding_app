package WxDataCoderGridPanel;
#######################################
#
#   This package branches the main functions outside the Frame package (to get outside of the 'new()')
#
#######################################

use Moose;
use Wx qw(:everything);
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

use Timing::WxDisplay::Panels::TSWxPanel;
extends 'TSWxPanel';

## set a local (shared) 'state' variable for indexing new instances....Moose does not seem to handle this..
my $key_index = 0;

has 'this_version' => (isa => 'Num', is => 'ro', default => 0.100102 );
has 'PANEL_NAME' => (isa => 'Str', is => 'rw', default => 'gridpanel' );

has 'CHECK_BOX_FIELDS' => (isa => 'HashRef', is => 'rw', builder => '__check_box_fields' );

## builder methods
sub __check_box_fields {
	my $opt = {};
	my $subopt = {};
	$subopt->{id_set} = 0;
	$subopt->{label_text} = '';
	$subopt->{default_size} = 1;
	$subopt->{start_set} = 0;
	$subopt->{yaml_key} = 'start_daemon';
	$opt->{daemon_start_check} = $subopt;
	my $subopt1 = {};
	$subopt1->{id_set} = 0;
	$subopt1->{label_text} = '';
	$subopt1->{default_size} = 1;
	$subopt1->{start_set} = 0;
	$subopt1->{yaml_key} = 'start_core';
	$opt->{core_start_check} = $subopt1;
	my $subopt2 = {};
	$subopt2->{id_set} = 0;
	$subopt2->{label_text} = '';
	$subopt2->{default_size} = 1;
	$subopt2->{start_set} = 0;
	$subopt2->{yaml_key} = 'start_nodal';
	$opt->{nodal_start_check} = $subopt2;
	my $subopt3 = {};
	$subopt3->{id_set} = 0;
	$subopt3->{label_text} = '';
	$subopt3->{default_size} = 1;
	$subopt3->{start_set} = 0;
	$subopt3->{yaml_key} = 'start_dbh';
	$opt->{dbh_start_check} = $subopt3;
	
	return $opt;
}

sub build {
	my $self = shift;
	my $winframe = $self->{WINFRAME_PTR};
	my $cntrl_id = 0;
	if(@_) { $cntrl_id = shift; }
	if(!$cntrl_id) { $cntrl_id = 0; }
	my $cntrl_ct = $cntrl_id;
	my $_pmgr = $self->{PROCESS_MGR_OBJECT};
	my $_smgr = $_pmgr->_stateManager();
	my $settings = $winframe->getWxlayoutSettingsforFrame();
	my $main_app = $winframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	if(!defined $self->{WXFRAME_MGR_OBJECT}) {
		$self->{WXFRAME_MGR_OBJECT} = $_wfmgr;
	}
	my $carp = 1;
	my $disp = $settings;
	my $display_key = 'display_config';
	if(exists $settings->{$display_key}) {
		$disp = $settings->{$display_key};
	}
	my $panel = $self->{PANEL_NAME};
	my $stat_text_href = $self->{STATIC_TEXT_HREF};
	my $check_box_fields = $self->{CHECK_BOX_FIELDS};
	
	my $window_key = 'window';
	my $panels_key = 'panels';
	my $fonts_key = 'fonts';
	my $buttons_key = 'buttons';
	my $textcontrols_key = 'textcontrols';
	my $matrixblock_key = 'matrix_block';
	my $cboxcontrols_key = 'checkboxes';
	my $comboboxcontrols_key = 'comboboxes';
	my $clickeventnotice_key = 'datanotice';
	my $panel_title_key = 'panel_title';
	my $dataentry_key = 'data_entry';

	my $status_font_size = 10;
	if(exists $disp->{$fonts_key}->{status}->{size}) {
		$status_font_size = $disp->{$fonts_key}->{status}->{size};
	}
	my $row_font_size = 10;
	if(exists $disp->{$fonts_key}->{row}->{size}) {
		$row_font_size = $disp->{$fonts_key}->{row}->{size};
	}
	my $select_font_size = 10;
	if(exists $disp->{$fonts_key}->{select}->{size}) {
		$select_font_size = $disp->{$fonts_key}->{select}->{size};
	}
	my $snall_text_font_size = 9;
	if(exists $disp->{$fonts_key}->{small_textbox}->{size}) {
		$snall_text_font_size = $disp->{$fonts_key}->{small_textbox}->{size};
	}
	my $submit_out_font_size = 10;
	if(exists $disp->{$fonts_key}->{submit_outgoing}->{size}) {
		$submit_out_font_size = $disp->{$fonts_key}->{submit_outgoing}->{size};
	}
	my $submit_in_font_size = 10;
	if(exists $disp->{$fonts_key}->{submit_incoming}->{size}) {
		$submit_out_font_size = $disp->{$fonts_key}->{submit_incoming}->{size};
	}
	my $combobox_font_size = 11;
	if(exists $disp->{$fonts_key}->{combobox}->{size}) {
		$combobox_font_size = $disp->{$fonts_key}->{combobox}->{size};
	}
	my $panel_title_font_size = 10;
	if(exists $disp->{$fonts_key}->{panel_title}->{size}) {
		$panel_title_font_size = $disp->{$fonts_key}->{panel_title}->{size};
	}
	my $sfont = Wx::Font->new($status_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $hfont = Wx::Font->new($status_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $rfont = Wx::Font->new($row_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $selfont = Wx::Font->new($select_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $smfont = Wx::Font->new($snall_text_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $suboutfont = Wx::Font->new($submit_out_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $subinfont = Wx::Font->new($submit_in_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $cbfont = Wx::Font->new($combobox_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $tfont = Wx::Font->new($panel_title_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);

	####
	## Reader 1 Panel
	####
	my $p_space = 2;
	if(exists $disp->{$window_key}->{panel_spacing}) {
		$p_space = $disp->{$window_key}->{panel_spacing};
	}

	
	my $mainp_ht = 100;
	my $mainp_wd = 700;
	my $mainp_start_x = 0;
	my $mainp_start_y = 0;
	$mainp_ht = $self->_set_height($disp->{$panels_key}->{$panel},$mainp_ht);
	$mainp_wd = $self->_set_width($disp->{$panels_key}->{$panel},$mainp_wd);
	my $last_panel_ht = 0;
	my $last_panel_wd = 0;

#	$panel_ht = $mainp_ht;
#	$panel_wd = $mainp_wd;
	my $panel_start_x = 0;
	my $panel_start_y = 0;
	if(exists $disp->{$panels_key}->{$panel}->{origin}->{X}) {
		$panel_start_x = $disp->{$panels_key}->{$panel}->{origin}->{X};
	}
	if(exists $disp->{$panels_key}->{$panel}->{origin}->{Y}) {
		$panel_start_y = $disp->{$panels_key}->{$panel}->{origin}->{Y};
	}
	
	my $panel_wd = 30;
	if(exists $disp->{$panels_key}->{$panel}->{size}->{width}) {
		$panel_wd = $disp->{$panels_key}->{$panel}->{size}->{width};
	}
	my $panel_ht = 10;
	if(exists $disp->{$panels_key}->{$panel}->{size}->{height}) {
		$panel_ht = $disp->{$panels_key}->{$panel}->{size}->{height};
	}
	$panel_start_y = $panel_start_y + $p_space;

	print "[PANEL] {$panel} wd[$panel_wd] ht[$panel_ht] start_x[$panel_start_x] start_y[$panel_start_y]\n";

	$winframe->{$panel} = Wx::Panel->new($winframe, -1, [$panel_start_x,$panel_start_y], [$panel_wd,$panel_ht], wxBORDER_NONE );

#	print "== STARTED [$panel] at [$panel_start_x,$panel_start_y] to [$panel_wd,$panel_ht]\n";

	####
	## does the panel have a title?
	####
	my $title = undef;
	my $title_x = 0;
	my $title_y = 0;
	my $title_wd = 0;
	my $title_ht = 0;
	if(exists $disp->{$panels_key}->{$panel}->{$textcontrols_key}->{$panel_title_key}) {
		$title_wd = $disp->{$panels_key}->{$panel}->{$textcontrols_key}->{$panel_title_key}->{size}->{width};
		$title_ht = $disp->{$panels_key}->{$panel}->{$textcontrols_key}->{$panel_title_key}->{size}->{height};
		$title_x = $disp->{$panels_key}->{$panel}->{$textcontrols_key}->{$panel_title_key}->{origin}->{X};
		$title_y = $disp->{$panels_key}->{$panel}->{$textcontrols_key}->{$panel_title_key}->{origin}->{Y};
	}
	if(exists $disp->{panel_titles}->{$panel}) {
		$title = $disp->{panel_titles}->{$panel};
	}
	if($title && scalar($title)) {
		my $nam = $panel . 'title';
		$winframe->{$nam} = Wx::StaticText->new( $winframe->{$panel},-1, $title, [$title_x,$title_y], [$title_wd,$title_ht], );
		$winframe->{$nam}->SetFont($tfont);
	}


}

no Moose; # keywords are removed from the TSCourse package

1;
