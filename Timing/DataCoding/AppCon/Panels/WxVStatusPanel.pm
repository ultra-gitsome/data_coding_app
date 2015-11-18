package WxVStatusPanel;
#######################################
#
#   This package branches the main functions outside the Frame package (to get outside of the 'new()')
#
#######################################

use Moose;

use Wx qw(:everything);

extends 'TSWxPanel';

## set a local (shared) 'state' variable for indexing new instances....Moose does not seem to handle this..
my $key_index = 0;

has 'this_version' => (isa => 'Num', is => 'ro', default => 0.100101 );

has 'PANEL_NAME' => (isa => 'Str', is => 'rw', default => 'statuspanel' );
has 'OBJECT_KEY' => (isa => 'Str', is => 'rw', builder => '__set_key' );

## builder methods

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
	my $frameident = $winframe->getFrameIdent();
	my $carp = 1;
	my $trace = 1;
	my $disp = $settings;
	my $display_key = 'display_config';
	if(exists $settings->{$display_key}) {
		$disp = $settings->{$display_key};
	}
	my $panel = $self->{PANEL_NAME};
	my $check_box_fields = $self->{CHECK_BOX_FIELDS};
	
	my $panels_key = 'panels';
	my $fonts_key = 'fonts';
	my $buttons_key = 'buttons';
	my $textcontrols_key = 'textcontrols';
	my $matrixblock_key = 'matrix_block';
	my $cboxcontrols_key = 'checkboxes';
	my $comboboxcontrols_key = 'comboboxes';
	my $clickeventnotice_key = 'datanotice';
	my $panel_ht = 0;
	my $panel_wd = 0;
	my $panel_start_x = 0;
	my $panel_start_y = 0;
	my $p_spacing = 2;
	my $myhost = 'thishost';
	my $corehost = 'corehost';
	my $nodalhost = 'nodalhost';
	my $mainhost = 'mdatahost';
	my $displayhost = 'displayhost';
	my $lookup_start = 1;
	my $lookup_size = 1;
	my $no_id = 0;
	##	$static_text_fields
	my $disp_cont = $disp->{$panels_key}->{$panel}->{$textcontrols_key};
	my $bdisp_cont = $disp->{$panels_key}->{$panel}->{$buttons_key};
	my $chdisp_cont = $disp->{$panels_key}->{$panel}->{$cboxcontrols_key};

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
	my $statusbox_font_size = 7;
	if(exists $disp->{$fonts_key}->{statusbox}->{size}) {
		$statusbox_font_size = $disp->{$fonts_key}->{statusbox}->{size};
	}
	my $sfont = Wx::Font->new($status_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $hfont = Wx::Font->new($status_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $rfont = Wx::Font->new($row_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $selfont = Wx::Font->new($select_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $statfont = Wx::Font->new($statusbox_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);

	####
	## statuspanel
	####

	## initialize lazy setup of control fields
	my $btn_cntl_href = $self->get_button_fields();
	my $input_cntl_href = $self->get_input_fields();
	my $static_cntl_href = $self->get_static_fields();
	my $input_text_fields = $self->{INPUT_TEXT_FIELDS};
	my $static_text_fields = $self->{STATIC_TEXT_FIELDS};

	$panel_ht = $self->_set_height($disp->{$panels_key}->{$panel},$panel_ht);
	$panel_wd = $self->_set_width($disp->{$panels_key}->{$panel},$panel_wd);

	$panel_start_x = $self->_set_start_x($disp->{$panels_key}->{$panel},$panel_start_x);
	$panel_start_y = $self->_set_start_y($disp->{$panels_key}->{$panel},$panel_start_y);
	
	print "[PANEL] {$panel} wd[$panel_wd] ht[$panel_ht] start_x[$panel_start_x] start_y[$panel_start_y]\n" if $carp;

	$winframe->{$panel} = Wx::Panel->new($winframe, -1, [$panel_start_x,$panel_start_y], [$panel_wd,$panel_ht], wxBORDER_NONE );

	my $rid = 0;
	my $evtsubname = undef;
	my $cntl_href = undef;
	
	####
	## special control buttons
	####
	my $cname = "savebutton";
	$rid = 0;
	$evtsubname = 'saveNow';
	$cntl_href = $btn_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
#	$rid = $self->_set_Button_HK(cname => $cname, btn_disp_cntrls => $bdisp_cont, btn_fields => $btn_cntl_href, id => $cntrl_id, font => $statfont,);
#	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
#	$_wfmgr->event_pre_set('button',$cname,$evtsubname);

	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $statfont, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);


	$cname = "closebutton";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $btn_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_Button_HK(cname => $cname, btn_disp_cntrls => $bdisp_cont, btn_fields => $btn_cntl_href, id => $cntrl_id, font => $statfont,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->event_pre_set('button',$cname,$evtsubname);

	
	####
	## VSTATUS info boxes
	####

	$cname = 'textboxlogger';
	my $box_type = 0;
	if(exists $disp_cont->{$cname}->{multiline}) {
		$box_type = $disp_cont->{$cname}->{multiline};
	}
	$rid = 0;
	if($box_type) {
#		$rid = $self->_set_textBox_HK(winframe => $winframe, panel => $panel, cname => $cname, text_disp_cntrls => $disp_cont, input_fields => $input_fields, id => $no_id, font => $rfont, start_x => $col_7_start_x, start_y => $row_3_start_y,);
		$rid = $self->_set_textBox_HK(winframe => $winframe, panel => $panel, cname => $cname, text_disp_cntrls => $disp_cont, input_fields => $input_cntl_href, id => $no_id, font => $rfont, );
	} else {
		$rid = $self->_set_textCtrl_HK(winframe => $winframe, panel => $panel, cname => $cname, text_disp_cntrls => $disp_cont, static_fields => $static_cntl_href, id => $no_id, font => $rfont, );
	}
	$_wfmgr->textfieldkey_by_wxframe($frameident,$cname,'vlogger',$trace);
	$_wfmgr->set_panel_textboxes_by_wxframe(wxframe_ident => $frameident, textboxname => $cname, trace => $trace);

	$_wfmgr->set_active_text_box($cname,1);

	$cname = 'textboxstatus';
	$box_type = 0;
	if(exists $disp_cont->{$cname}->{multiline}) {
		$box_type = $disp_cont->{$cname}->{multiline};
	}
	$rid = 0;
	if($box_type) {
		$rid = $self->_set_textBox_HK(winframe => $winframe, panel => $panel, cname => $cname, text_disp_cntrls => $disp_cont, input_fields => $input_cntl_href, id => $no_id, font => $rfont, );
	} else {
		$rid = $self->_set_textCtrl_HK(winframe => $winframe, panel => $panel, cname => $cname, text_disp_cntrls => $disp_cont, input_fields => $static_cntl_href, id => $no_id, font => $rfont, );
	}
	$_wfmgr->textfieldkey_by_wxframe($frameident,$cname,'vstatus',$trace);
	$_wfmgr->set_panel_textboxes_by_wxframe(wxframe_ident => $frameident, textboxname => $cname, trace => $trace);
	
	$_wfmgr->set_active_text_box($cname,1);
	$_wfmgr->set_panel_textboxes_in_wxframemgr(panelkey => 'VSTATUS',boxkey => 'LOWER', textboxname => $cname, carp => 1);
	return 1;
			
}

no Moose; # keywords are removed from the TSCourse package

1;
