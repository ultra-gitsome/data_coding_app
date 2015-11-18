package TSRowInfoPanel;
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


has 'PANEL_NAME' => (isa => 'Str', is => 'rw', default => 'rowinfopanel' );

has 'STATIC_TEXT_HREF' => (isa => 'HashRef', is => 'rw', default => sub { {} });
has 'STATIC_TEXT_FIELDS_SUPP' => (isa => 'HashRef', is => 'rw', builder => '__static_text_fields_supp' );
has 'CHECK_BOX_FIELDS' => (isa => 'HashRef', is => 'rw', builder => '__check_box_fields' );

## builder methods
sub __static_text_fields_supp {
	my $opt = {};
	my $subopt4 = {};
	$subopt4->{id_set} = 0;
	$subopt4->{label_text} = '';
	$subopt4->{default_size} = 1;
	$subopt4->{start_set} = 0;
	$subopt4->{yaml_key} = undef;
	$subopt4->{data_fetch_key} = 'thishost';
	$subopt4->{data_fetch_method} = 'get_ip_on_host';
	$opt->{my_ip_address_select} = $subopt4;
	my $subopt5 = {};
	$subopt5->{id_set} = 0;
	$subopt5->{label_text} = '';
	$subopt5->{default_size} = 1;
	$subopt5->{start_set} = 0;
	$subopt5->{yaml_key} = undef;
	$subopt5->{data_fetch_key} = 'thishost';
	$subopt5->{data_fetch_method} = 'get_daemonkey_on_host';
	$opt->{my_ip_address_dmn} = $subopt5;
	my $subopt7 = {};
	$subopt7->{id_set} = 0;
	$subopt7->{label_text} = '';
	$subopt7->{default_size} = 1;
	$subopt7->{start_set} = 0;
	$subopt7->{yaml_key} = undef;
	$subopt7->{data_fetch_key} = 'corehost';
	$subopt7->{data_fetch_method} = 'get_ip_on_host';
	$opt->{core_ip_address_select} = $subopt7;
	my $subopt8 = {};
	$subopt8->{id_set} = 0;
	$subopt8->{label_text} = '';
	$subopt8->{default_size} = 1;
	$subopt8->{start_set} = 0;
	$subopt8->{yaml_key} = undef;
	$subopt8->{data_fetch_key} = 'corehost';
	$subopt8->{data_fetch_method} = 'get_daemonkey_on_host';
	$opt->{core_ip_address_dmn} = $subopt8;
	my $subopt9 = {};
	$subopt9->{id_set} = 0;
	$subopt9->{label_text} = '';
	$subopt9->{default_size} = 1;
	$subopt9->{start_set} = 0;
	$subopt9->{yaml_key} = undef;
	$subopt9->{data_fetch_key} = 'corehost';
	$subopt9->{data_fetch_method} = 'get_daemon_status';
	$opt->{core_ip_address_stat} = $subopt9;
	my $subopt11 = {};
	$subopt11->{id_set} = 0;
	$subopt11->{label_text} = '';
	$subopt11->{default_size} = 1;
	$subopt11->{start_set} = 0;
	$subopt11->{yaml_key} = undef;
	$subopt11->{data_fetch_key} = 'nodalhost';
	$subopt11->{data_fetch_method} = 'get_ip_on_host';
	$opt->{nodal_ip_address_select} = $subopt11;
	my $subopt12 = {};
	$subopt12->{id_set} = 0;
	$subopt12->{label_text} = '';
	$subopt12->{default_size} = 1;
	$subopt12->{start_set} = 0;
	$subopt12->{yaml_key} = undef;
	$subopt12->{data_fetch_key} = 'nodalhost';
	$subopt12->{data_fetch_method} = 'get_daemonkey_on_host';
	$opt->{nodal_ip_address_dmn} = $subopt12;
	my $subopt13 = {};
	$subopt13->{id_set} = 0;
	$subopt13->{label_text} = '';
	$subopt13->{default_size} = 1;
	$subopt13->{start_set} = 0;
	$subopt13->{yaml_key} = undef;
	$subopt13->{data_fetch_key} = 'nodalhost';
	$subopt13->{data_fetch_method} = 'get_daemon_status';
	$opt->{nodal_ip_address_stat} = $subopt13;
	my $subopt15 = {};
	$subopt15->{id_set} = 0;
	$subopt15->{label_text} = '';
	$subopt15->{default_size} = 1;
	$subopt15->{start_set} = 0;
	$subopt15->{yaml_key} = undef;
	$subopt15->{data_fetch_key} = 'mdatahost';
	$subopt15->{data_fetch_method} = 'get_ip_on_host';
	$opt->{mdata_ip_address_select} = $subopt15;
	my $subopt16 = {};
	$subopt16->{id_set} = 0;
	$subopt16->{label_text} = '';
	$subopt16->{default_size} = 1;
	$subopt16->{start_set} = 0;
	$subopt16->{yaml_key} = undef;
	$subopt16->{data_fetch_key} = 'mdatahost';
	$subopt16->{data_fetch_method} = 'get_daemonkey_on_host';
	$opt->{mdata_ip_address_dmn} = $subopt16;
	my $subopt17 = {};
	$subopt17->{id_set} = 0;
	$subopt17->{label_text} = '';
	$subopt17->{default_size} = 1;
	$subopt17->{start_set} = 0;
	$subopt17->{yaml_key} = undef;
	$subopt17->{data_fetch_key} = 'mdatahost';
	$subopt17->{data_fetch_method} = 'get_daemon_status';
	$opt->{mdata_ip_address_stat} = $subopt17;
	my $subopt19 = {};
	$subopt19->{id_set} = 0;
	$subopt19->{label_text} = '';
	$subopt19->{default_size} = 1;
	$subopt19->{start_set} = 0;
	$subopt19->{yaml_key} = undef;
	$subopt19->{data_fetch_key} = 'displayhost';
	$subopt19->{data_fetch_method} = 'get_ip_on_host';
	$opt->{display_ip_address_select} = $subopt19;
	my $subopt20 = {};
	$subopt20->{id_set} = 0;
	$subopt20->{label_text} = '';
	$subopt20->{default_size} = 1;
	$subopt20->{start_set} = 0;
	$subopt20->{yaml_key} = undef;
	$subopt20->{data_fetch_key} = 'displayhost';
	$subopt20->{data_fetch_method} = 'get_daemonkey_on_host';
	$opt->{display_ip_address_dmn} = $subopt20;
	my $subopt21 = {};
	$subopt21->{id_set} = 0;
	$subopt21->{label_text} = '';
	$subopt21->{default_size} = 1;
	$subopt21->{start_set} = 0;
	$subopt21->{yaml_key} = undef;
	$subopt21->{data_fetch_key} = 'displayhost';
	$subopt21->{data_fetch_method} = 'get_daemon_status';
	$opt->{display_ip_address_stat} = $subopt21;
	my $subopt22 = {};
	$subopt22->{id_set} = 0;
	$subopt22->{label_text} = 'Start Daemon';
	$subopt22->{default_size} = 1;
	$subopt22->{start_set} = 1;
	$subopt22->{yaml_key} = 'daemon_start_label';
	$opt->{start_daemon_txt} = $subopt22;
	my $subopt23 = {};
	$subopt23->{id_set} = 0;
	$subopt23->{label_text} = 'Start Core Servers';
	$subopt23->{default_size} = 1;
	$subopt23->{start_set} = 1;
	$subopt23->{yaml_key} = 'core_start_label';
	$opt->{start_core_txt} = $subopt23;
	my $subopt24 = {};
	$subopt24->{id_set} = 0;
	$subopt24->{label_text} = 'Start Nodal Servers';
	$subopt24->{default_size} = 1;
	$subopt24->{start_set} = 1;
	$subopt24->{yaml_key} = 'nodal_start_label';
	$opt->{start_nodal_txt} = $subopt24;
	my $subopt25 = {};
	$subopt25->{id_set} = 0;
	$subopt25->{label_text} = 'Start DB Handle';
	$subopt25->{default_size} = 1;
	$subopt25->{start_set} = 1;
	$subopt25->{yaml_key} = 'dbh_start_label';
	$opt->{start_dbh_txt} = $subopt25;
	my $subopt27 = {};
	$subopt27->{id_set} = 0;
	$subopt27->{label_text} = 'Primary Server';
	$subopt27->{default_size} = 1;
	$subopt27->{start_set} = 1;
	$subopt27->{yaml_key} = 'servernotice';
	$subopt21->{data_fetch_key} = 'wfmgr';
	$subopt21->{data_fetch_method} = 'wxframe_nserver_status';
	$opt->{servernotice} = $subopt27;

	return $opt;
}
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
#	my $frame_key = $winframe->wxframe_key_value();
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
#	my $stat_text_href = $self->{STATIC_TEXT_HREF};
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

	##	matrix block config
	my $matrix_cont = $disp->{$panels_key}->{$panel}->{$matrixblock_key};
	my $col_1_start_x = $matrix_cont->{origin}->{X};
	my $row_1_start_y = $matrix_cont->{origin}->{Y};
	my $row_height = $matrix_cont->{row_height};
	my $header_row_height = $matrix_cont->{header_row_height};
	my $col_spacing = $matrix_cont->{col_spacing};
	my $col_2_start_x = $col_1_start_x + $col_spacing + $matrix_cont->{col_1_width};
	my $col_3_start_x = $col_2_start_x + $col_spacing + $matrix_cont->{col_2_width};
	my $col_4_start_x = $col_3_start_x + $col_spacing + $matrix_cont->{col_3_width};
	my $col_5_start_x = $col_4_start_x + $col_spacing + $matrix_cont->{col_4_width};
	my $col_6_start_x = $col_5_start_x + $col_spacing + $matrix_cont->{col_5_width};
	my $col_7_start_x = $col_6_start_x + $col_spacing + $matrix_cont->{col_6_width};
	my $col_8_start_x = $col_7_start_x + $col_spacing + $matrix_cont->{col_7_width};
	my $col_9_start_x = $col_8_start_x + $col_spacing + $matrix_cont->{col_8_width};

	##	control values from gui settings file
	my $disp_cont = $disp->{$panels_key}->{$panel}->{$textcontrols_key};
	my $bdisp_cont = $disp->{$panels_key}->{$panel}->{$buttons_key};
	my $chdisp_cont = $disp->{$panels_key}->{$panel}->{$cboxcontrols_key};
	my $cbdisp_cont = $disp->{$panels_key}->{$panel}->{$comboboxcontrols_key};

	## initialize lazy setup of button fields
	my $btn_cntl_href = $self->get_button_fields();
	my $input_cntl_href = $self->get_input_fields();
	my $static_cntl_href = $self->get_static_fields();
	my $combo_cntl_href = $self->get_combo_fields();
#	print "[BUILD] buttons [$btn_cntl_href] ct[".scalar(keys %$btn_cntl_href)."]\n";
#	foreach my $but (keys %$btn_cntl_href) {
#		print "....btn[$but] val[".$btn_cntl_href->{$but}."]\n";
#	}


	####
	## Row Info Panel
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


	my $cname = undef;
	my $subname = 'on_click_update_label';
	my $evtsubname = undef;
	my $rid = 0;
	my $butid = 0;
	my $contid = 0;
	my $cntl_href = undef;
	my $btn_wd = 0;
	my $btn_ht = 0;

	#############
	## ROW 1 
	## DISPLAY mmnu_colgrp_1-5 controls
	#############

	$cname = 'mnum_colgrp_1_text';
	$rid = 0;
#	$evtsubname = 'on_click_submit';
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	my $col_s_x = $col_1_start_x + 30;
	#my $contid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
#		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rfont, start_x => $col_1_start_x, start_y => $row_1_start_y,);
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	} else {
#		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_text_fields, id => $contid, font => $rfont, start_x => $col_1_start_x, start_y => $row_1_start_y,);
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
#	$_wfmgr->panel_event_pre_set($panel,'input',$cname,$evtsubname);

	$cname = 'mnum_colgrp_2_text';
	$rid = 0;
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$col_s_x = $col_2_start_x + 30;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);

	$cname = 'mnum_colgrp_3_text';
	$rid = 0;
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$col_s_x = $col_3_start_x + 30;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);

	$cname = 'mnum_colgrp_4_text';
	$rid = 0;
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$col_s_x = $col_4_start_x + 30;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);

	$cname = 'mnum_colgrp_5_text';
	$rid = 0;
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$col_s_x = $col_5_start_x + 30;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $rfont, start_x => $col_s_x, start_y => $row_1_start_y,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);

	#############
	## ROW 2 
	## DISPLAY mmnu_colgrp_2 controls
	#############
	my $row_2_start_y = $row_1_start_y + $header_row_height;


}

no Moose; # keywords are removed from the TSCourse package

1;
