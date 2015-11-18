package WxDataCoderMainPanel;
#######################################
#
#   This package branches the main functions outside the Frame package (to get outside of the 'new()')
#
#######################################

use Moose;
use Wx qw(:everything);

use Timing::WxDisplay::Panels::TSWxPanel;
extends 'TSWxPanel';

## set a local (shared) 'state' variable for indexing new instances....Moose does not seem to handle this..
my $key_index = 0;

has 'this_version' => (isa => 'Num', is => 'ro', default => 0.100102 );
has 'PANEL_NAME' => (isa => 'Str', is => 'rw', default => 'mainpanel' );


## builder methods

sub build {
	my $self = shift;
	my $winframe = $self->{WINFRAME_PTR};
	my $cntrl_id = 0;
	if(@_) { $cntrl_id = shift; }
	if(!$cntrl_id) { $cntrl_id = 0; }
	my $cntrl_ct = $cntrl_id;
	my $settings = $winframe->getWxlayoutSettingsforFrame();
	my $main_app = $winframe->{MAIN_APP};
	my $_wfmgr = $main_app->wxFrameMgr();
	if(!defined $self->{WXFRAME_MGR_OBJECT}) {
		$self->{WXFRAME_MGR_OBJECT} = $_wfmgr;
	}

	my $carp = 1;
	my $trace = $carp;
	my $disp = $settings;
	my $display_key = 'display_config';
	if(exists $settings->{$display_key}) {
		$disp = $settings->{$display_key};
	}
	my $panel = $self->{PANEL_NAME};
	my $stat_text_href = $self->{STATIC_TEXT_HREF};
	my $check_box_fields = $self->{CHECK_BOX_FIELDS};
	
	my $panels_key = 'panels';
	my $fonts_key = 'fonts';
	my $buttons_key = 'buttons';
	my $textcontrols_key = 'textcontrols';
	my $matrixblock_key = 'matrix_block';
	my $cboxcontrols_key = 'checkboxes';
	my $comboboxcontrols_key = 'comboboxes';
	my $clickeventnotice_key = 'datanotice';
	my $primary_list_key = 'data_primary_control_list_mapping';

	my $status_font_size = 10;
	if(exists $disp->{$fonts_key}->{status}->{size}) {
		$status_font_size = $disp->{$fonts_key}->{status}->{size};
	}
	my $row_font_size = 10;
	if(exists $disp->{$fonts_key}->{row}->{size}) {
		$row_font_size = $disp->{$fonts_key}->{row}->{size};
	}
	my $row_label_font_size = 10;
	if(exists $disp->{$fonts_key}->{row_label}->{size}) {
		$row_label_font_size = $disp->{$fonts_key}->{row_label}->{size};
	}
	my $row_label_bold_font_size = 11;
	if(exists $disp->{$fonts_key}->{row_label_bold}->{size}) {
		$row_label_bold_font_size = $disp->{$fonts_key}->{row_label_bold}->{size};
	}
	my $select_font_size = 10;
	if(exists $disp->{$fonts_key}->{select}->{size}) {
		$select_font_size = $disp->{$fonts_key}->{select}->{size};
	}
	my $snall_text_font_size = 9;
	if(exists $disp->{$fonts_key}->{small_textbox}->{size}) {
		$snall_text_font_size = $disp->{$fonts_key}->{small_textbox}->{size};
	}
	my $sfont = Wx::Font->new($status_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $hfont = Wx::Font->new($status_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $rfont = Wx::Font->new($row_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $rlfont = Wx::Font->new($row_label_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $selfont = Wx::Font->new($select_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $smfont = Wx::Font->new($snall_text_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $rlbfont = Wx::Font->new($row_label_bold_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);

	## fetch primary control list for yaml data
	my $plist_href = $disp->{$primary_list_key};
	if(!defined $plist_href or $plist_href!~/HASH/i) {
		$plist_href = {};
	}
	my $order_by = 'key';

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
	my $col_10_start_x = $col_9_start_x + $col_spacing + $matrix_cont->{col_9_width};
	my $col_11_start_x_pre = $col_10_start_x + $col_spacing + $matrix_cont->{col_10_width} - $matrix_cont->{col_10_width};
	my $col_12_start_x = $col_11_start_x_pre + $col_spacing + $matrix_cont->{col_11_width};
	my $col_11_start_x = $col_12_start_x - $matrix_cont->{col_10_width};
	my $col_13_start_x = $col_12_start_x + $col_spacing + $matrix_cont->{col_12_width};

	
	my $panel_ht = 0;
	my $panel_wd = 0;
	my $panel_start_x = 0;
	my $panel_start_y = 0;
	my $mainp_ht = 100;
	my $mainp_wd = 700;
	my $mainp_start_x = 0;
	my $mainp_start_y = 0;
	$mainp_ht = $self->_set_height($disp->{$panels_key}->{$panel},$mainp_ht);
	$mainp_wd = $self->_set_width($disp->{$panels_key}->{$panel},$mainp_wd);

	$panel_ht = $mainp_ht;
	$panel_wd = $mainp_wd;
	$panel_start_x = $mainp_start_x;
	$panel_start_y = $mainp_start_y;
	
	print "[PANEL] {$panel} wd[$panel_wd] ht[$panel_ht] start_x[$panel_start_x] start_y[$panel_start_y]\n";

	$winframe->{$panel} = Wx::Panel->new($winframe, -1, [$panel_start_x,$panel_start_y], [$panel_wd,$panel_ht], wxBORDER_NONE );

	##	$static_text_fields
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
	my $button_fields = $self->{BUTTON_FIELDS};
	my $input_text_fields = $self->{INPUT_TEXT_FIELDS};
	my $static_text_fields = $self->{STATIC_TEXT_FIELDS};
#	print "[BUILD] static text [$static_cntl_href] ct[".scalar(keys %$static_cntl_href)."]\n";
#	foreach my $but (keys %$static_cntl_href) {
#		print "....static text[$but] val[".$static_cntl_href->{$but}."]\n";
#	}
	

	my $no_id = 0;
	my $lookup_start = 1;
	my $lookup_size = 1;
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
	## ROW 1 - Header/Status...moved to right
	#############

	$cname = 'start_time_disp';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $sfont,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $sfont,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname); 
	
	$cname = 'time_diff';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $sfont,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $sfont,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname); 
	
	$cname = 'sentence_state';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $sfont,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $sfont,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname); 

	$cntrl_id++;
	$cntrl_ct++;

	####
	## set the number of checkpt drop down fields on panel
	## ...should be 3
	####
	$_wfmgr->number_sp_fields(3);
	
	#############
	## ROW 2
	#############
	my $row_2_start_y = $row_1_start_y + $header_row_height;
#	my $row_3_start_y = $row_2_start_y + $row_height;


	#############
	## ROW 1 (+ row header)
	## DISPLAY submit_1 controls
	#############

	$cname = 'select_interviewee_label';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rlfont, col_start_x => $col_1_start_x, row_start_y => $row_1_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $rlfont, col_start_x => $col_1_start_x, row_start_y => $row_1_start_y,);
	}

	$cname = "interviewee_select";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $combo_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	my $combo_item_list = [];
	my $arr_ref = $_wfmgr->populate_combobox_array_by_name($cname,$plist_href,$trace);
	foreach my $c (@$arr_ref) {
		push @$combo_item_list,$c;
	}
	my @c_arr = ('None');

	$rid = $self->_set_panel_comboBox_HK(cname => $cname, panel_cntrls => $combo_cntl_href, combo_item_list => $combo_item_list, font => $rfont, col_start_x => $col_2_start_x, row_start_y => $row_1_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'combo', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'combo',
				src_name => '',
				up1_type => 'combo',
				up1_name => "topic_select",
				up2_name => "sentence_select",
				trace => $trace,
				);

	$cname = "lock_parsing";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	## NOTE: 'panel_event_pre_set_by_wxframe' and '_set_panel_Button_' are a matched set...use both or none
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_3_start_x, row_start_y => $row_1_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);
	## set initial parse lock on frame
	$_wfmgr->frame_run_states_by_statekey_framekey($winframe->{WXFRAME_KEY_VALUE},'parse_lock',1);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'button',
				src_name => '',
				up1_type => 'label',
				up1_name => "Lock Parsing",
				up2_name => "UnLock Parsing",
				trace => $trace,
				);

	$cname = "run_recode_stats";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_8_start_x, row_start_y => $row_1_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "run_aspect_calc";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_9_start_x, row_start_y => $row_1_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "run_write_sheets";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_12_start_x, row_start_y => $row_1_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "run_recodes";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_12_start_x, row_start_y => $row_1_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "test_run_timer";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_12_start_x, row_start_y => $row_1_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "run_atx_files";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_13_start_x, row_start_y => $row_1_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);


	#############
	#############
	## ROW 2 (+ header)
	## DISPLAY submit_2 controls
	#############
	my $row_3_start_y = $row_2_start_y + $row_height;

	$cname = 'select_topic_label';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rlfont, col_start_x => $col_1_start_x, row_start_y => $row_2_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $rlfont, col_start_x => $col_1_start_x, row_start_y => $row_2_start_y,);
	}

	$cname = "topic_select";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $combo_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$combo_item_list = [];
	foreach my $c (@c_arr) {
		push @$combo_item_list,$c;
	}

	$rid = $self->_set_panel_comboBox_HK(cname => $cname, panel_cntrls => $combo_cntl_href, combo_item_list => $combo_item_list, font => $rfont, col_start_x => $col_2_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'combo', name => $cname, subname => $evtsubname);

	$_wfmgr->gui_wxapp_ctrls_sync5(
				key => $cname,
				src_type => 'combo',
				src_name => '',
				up1_type => 'combo',
				up1_name => "sentence_select",
				up2_name => "sentence_text_selected",
				up3_name => "sentence_text_selected_pre",
				up4_name => "sentence_text_selected_post",
				trace => $trace,
				);


	$cname = "run_parse";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_5_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "run_coding";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_7_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "run_set_codes";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_9_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "run_recode_clean";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_11_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);


	$cname = "run_dist_calc";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $rfont, col_start_x => $col_13_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	## must use 'panel_event_pre_set_by_wxframe' when using '_set_panel_Button_'
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);

	$cname = "select_new_topic";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $combo_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	if(exists $cntl_href->{order_by} and $cntl_href->{order_by}) {
		$order_by = $cntl_href->{order_by};
	}
	$combo_item_list = [];
	$arr_ref = $_wfmgr->populate_combobox_array_by_name_ordered(cname => $cname, plist => $plist_href, order_by => $order_by, trace => $trace);
	for (my $c=0; $c<scalar(@$arr_ref); $c++) {
		push @$combo_item_list,$arr_ref->[$c];
	}
	push @$combo_item_list,'z_NEW_TOPIC';
#	$rid = $self->_set_comboBox_HK(cname => $cname, combo_disp_cntrls => $cbdisp_cont, panel_fields => $combo_cntl_href, combo_item_list => $combo_item_list, id => $cntrl_id, font => $rfont, col_start_x => $col_8_start_x, row_start_y => $row_3_start_y,);
#	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
#	$_wfmgr->panel_event_pre_set($panel,'combo',$cname,$evtsubname);

	$rid = $self->_set_panel_comboBox_HK(cname => $cname, panel_cntrls => $combo_cntl_href, combo_item_list => $combo_item_list, font => $rfont, col_start_x => $col_10_start_x, row_start_y => $row_3_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'combo', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'combo',
				src_name => 'new_topic',
				up1_type => 'text',
				up1_name => "topic",
				trace => $trace,
				);


	#############
	#############
	## ROW 3 (+ header)
	## DISPLAY submit_3 controls
	#############
	my $row_4_start_y = $row_3_start_y + $row_height;

	$cname = 'sentence_tskey';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $sfont,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $sfont,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname); 

	$cname = 'select_sentence_label';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $contid, font => $rlfont, col_start_x => $col_1_start_x, row_start_y => $row_3_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $contid, font => $rlfont, col_start_x => $col_1_start_x, row_start_y => $row_3_start_y,);
	}

	$cname = "sentence_select";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $combo_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$combo_item_list = [];

	$rid = $self->_set_panel_comboBox_HK(cname => $cname, panel_cntrls => $combo_cntl_href, combo_item_list => $combo_item_list, font => $rfont, col_start_x => $col_2_start_x, row_start_y => $row_3_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'combo', name => $cname, subname => $evtsubname);

	$_wfmgr->gui_wxapp_ctrls_sync5(
				key => $cname,
				src_type => 'combo',
				up1_type => 'text',
				src_name => '',
				up2_name => "sentence_text_selected_pre",
				up3_name => "sentence_text_selected",
				up4_name => "sentence_text_selected_post",
				up5_name => "",
				trace => $trace,
				);

	$cname = "prev_sentence";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $smfont, col_start_x => $col_5_start_x, row_start_y => $row_3_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync5(
				key => $cname,
				src_type => 'combo',
				src_name => 'sentence_select',
				up1_type => 'text',
				up1_name => "sentence_text_selected_pre",
				up2_name => "sentence_text_selected",
				up3_name => "sentence_text_selected_post",
				up4_name => "",
				trace => $trace,
				);

	$cname = "next_sentence";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $smfont, col_start_x => $col_6_start_x, row_start_y => $row_3_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync5(
				key => $cname,
				src_type => 'combo',
				src_name => 'sentence_select',
				up1_type => 'text',
				up3_name => "sentence_text_selected_pre",
				up4_name => "sentence_text_selected",
				up5_name => "sentence_text_selected_post",
				trace => $trace,
				);

	$cname = "confirm_sentence";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $button_fields->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_Button_HK(cname => $cname, btn_disp_cntrls => $btn_cntl_href, font => $smfont, col_start_x => $col_8_start_x, row_start_y => $row_3_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'button', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync5(
				key => $cname,
				src_type => 'combo',
				src_name => 'sentence_select',
				up1_type => 'text',
				up3_name => "sentence_text_selected_pre",
				up4_name => "sentence_text_selected",
				up5_name => "sentence_text_selected_post",
				trace => $trace,
				);



	## set sentence textfield at bottom of main panel
	$cname = 'sentence_text_selected';
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, font => $rlbfont, );
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_text_fields, font => $rlbfont,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
#	$_wfmgr->panel_event_pre_set($panel,'input',$cname,$evtsubname);

	$cname = 'sentence_text_selected_pre';
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, font => $rfont, );
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_text_fields, font => $rfont,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);

	$cname = 'sentence_text_selected_post';
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, font => $rfont, );
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_text_fields, font => $rfont,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	
	## set scrolling text box on right of main panel
	$cname = 'textboxright';
	my $box_type = 0;
	if(exists $disp_cont->{$cname}->{multiline}) {
		$box_type = $disp_cont->{$cname}->{multiline};
	}
	$rid = 0;
	if($box_type) {
		$rid = $self->_set_textBox_HK(cname => $cname, text_disp_cntrls => $disp_cont, input_fields => $input_cntl_href, id => $no_id, font => $rfont, );
	} else {
		if(exists $disp_cont->{$cname}->{input_field}) {
			$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, id => $no_id, font => $rfont, );
		} else {
			$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, id => $no_id, font => $rfont, );
		}
	}
	$_wfmgr->set_active_text_box($cname,1);


}

no Moose; # keywords are removed from the TSCourse package

1;
