package WxDataCoderSpecialPanel;
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

####
## change the 'PANEL_NAME' to match panel config in tsGuiConfig...
####
has 'PANEL_NAME' => (isa => 'Str', is => 'rw', default => 'specialpanel' );


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
	my $trace = 1;
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
	my $rlfont = Wx::Font->new($row_label_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $rlbfont = Wx::Font->new($row_label_bold_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $selfont = Wx::Font->new($select_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $smfont = Wx::Font->new($snall_text_font_size, wxFONTFAMILY_SWISS, wxBOLD, wxNORMAL);
	my $suboutfont = Wx::Font->new($submit_out_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $subinfont = Wx::Font->new($submit_in_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $cbfont = Wx::Font->new($combobox_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);
	my $tfont = Wx::Font->new($panel_title_font_size, wxFONTFAMILY_SWISS, wxNORMAL, wxNORMAL);

	## fetch primary control list for yaml data
	my $plist_href = $disp->{$primary_list_key};
	if(!defined $plist_href or $plist_href!~/HASH/i) {
		$plist_href = {};
	}

	##	matrix block config
	my $matrix_cont = $disp->{$panels_key}->{$panel}->{$matrixblock_key};
	my $col_1_start_x = 0;
	my $row_1_start_y = 0;
	my $row_height = 0;
	my $header_row_height = 0;
	my $col_spacing = 0;
	my $col_2_start_x = 0;
	my $col_3_start_x = 0;
	my $col_4_start_x = 0;
	my $col_5_start_x = 0;
	my $col_6_start_x = 0;
	my $col_7_start_x = 0;
	my $col_8_start_x = 0;
	my $col_9_start_x = 0;
	##	matrix block config
	if(exists $disp->{$panels_key}->{$panel}->{$matrixblock_key} and scalar(keys %{$disp->{$panels_key}->{$panel}->{$matrixblock_key}})) {
		$col_1_start_x = $matrix_cont->{origin}->{X};
		$row_1_start_y = $matrix_cont->{origin}->{Y};
		$row_height = $matrix_cont->{row_height};
		$header_row_height = $matrix_cont->{header_row_height};
		$col_spacing = $matrix_cont->{col_spacing};
		$col_2_start_x = $col_1_start_x + $col_spacing + $matrix_cont->{col_1_width};
		$col_3_start_x = $col_2_start_x + $col_spacing + $matrix_cont->{col_2_width};
		$col_4_start_x = $col_3_start_x + $col_spacing + $matrix_cont->{col_3_width};
		$col_5_start_x = $col_4_start_x + $col_spacing + $matrix_cont->{col_4_width};
		$col_6_start_x = $col_5_start_x + $col_spacing + $matrix_cont->{col_5_width};
		$col_7_start_x = $col_6_start_x + $col_spacing + $matrix_cont->{col_6_width};
		$col_8_start_x = $col_7_start_x + $col_spacing + $matrix_cont->{col_7_width};
		$col_9_start_x = $col_8_start_x + $col_spacing + $matrix_cont->{col_8_width};
	}
	
	##	by control type display settings
	my $disp_cont = $disp->{$panels_key}->{$panel}->{$textcontrols_key};
	my $bdisp_cont = $disp->{$panels_key}->{$panel}->{$buttons_key};
	my $chdisp_cont = $disp->{$panels_key}->{$panel}->{$cboxcontrols_key};
	my $cbdisp_cont = $disp->{$panels_key}->{$panel}->{$comboboxcontrols_key};
	## initialize lazy setup of fields
	my $btn_cntl_href = $self->get_button_fields();
	my $input_cntl_href = $self->get_input_fields();
	my $static_cntl_href = $self->get_static_fields();
	my $combo_cntl_href = $self->get_combo_fields();
	my $chk_cntl_href = $self->get_checkbox_fields();
	
	####
	## Reader 2 Panel
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

	
	####
	## panel cname variables init...some are useless
	####
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
	my $order_by = 'key';


	#############
	## ROW 1 - Header/Status...moved to right
	#############
	
	### labels
	$cname = 'set_causality_label';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, font => $rlfont, col_start_x => $col_2_start_x, row_start_y => $row_1_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, font => $rlfont, col_start_x => $col_2_start_x, row_start_y => $row_1_start_y,);
	}

	$cname = 'set_views_label';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, font => $rlfont, col_start_x => $col_4_start_x, row_start_y => $row_1_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, font => $rlfont, col_start_x => $col_4_start_x, row_start_y => $row_1_start_y,);
	}
	
	$cname = 'set_roles_label';
	if(exists $input_cntl_href->{$cname}) {
		$cntl_href = $input_cntl_href->{$cname};
	} else {
		$cntl_href = $static_cntl_href->{$cname};
	}
	$rid = 0;
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, font => $rlfont, col_start_x => $col_6_start_x, row_start_y => $row_1_start_y,);
	} else {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_cntl_href, font => $rlfont, col_start_x => $col_6_start_x, row_start_y => $row_1_start_y,);
	}

	#############
	## ROW 2
	#############
	my $row_2_start_y = $row_1_start_y + $header_row_height;


	####
	## special causality checks
	####
	$cname = "cause";
	my $causal_index = 2;
	$rid = 0;
	$evtsubname = 'on_check';
	$cntl_href = $chk_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_checkBox_HK(cname => $cname, panel_cntrls => $chk_cntl_href, font => $cbfont, col_start_x => $col_2_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'checkbox', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'checkbox',
				src_name => $causal_index,
				up1_type => 'checkbox',
				up1_name => "effect",
				up2_name => "cause_n_effect",
				trace => $trace,
				);

	$cname = "perspective_level";
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $combo_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	if(exists $cntl_href->{order_by} and $cntl_href->{order_by}) {
		$order_by = $cntl_href->{order_by};
	}
	my $combo_item_list = [];
#	my $arr_ref = $_wfmgr->populate_combobox_array_by_name($cname,$plist_href,$trace);
	my $arr_ref = $_wfmgr->populate_combobox_array_by_name_ordered(cname => $cname, plist => $plist_href, order_by => $order_by, trace => $trace);
	foreach my $c (@$arr_ref) {
		push @$combo_item_list,$c;
	}
	$rid = $self->_set_panel_comboBox_HK(cname => $cname, panel_cntrls => $combo_cntl_href, combo_item_list => $combo_item_list, id => $cntrl_id, font => $rfont, col_start_x => $col_4_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'combo', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'combo',
				src_name => 'view',
				up1_type => 'text',
				up1_name => "level",
				trace => $trace,
				);

	$cname = "stakeholder_primary_role";
	$rid = 0;
	$combo_item_list = undef;
	$arr_ref = undef;
	$order_by = 'key';
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
	foreach my $c (@$arr_ref) {
		push @$combo_item_list,$c;
	}
	$rid = $self->_set_panel_comboBox_HK(cname => $cname, panel_cntrls => $combo_cntl_href, combo_item_list => $combo_item_list, id => $cntrl_id, font => $rfont, col_start_x => $col_6_start_x, row_start_y => $row_2_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'combo', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'combo',
				src_name => 'role',
				up1_type => 'text',
				up1_name => "primary",
				trace => $trace,
				);

	#############
	## ROW 3
	#############
	my $row_3_start_y = $row_2_start_y + $header_row_height;

	$cname = "effect";
	$causal_index = 3;
	$rid = 0;
	$evtsubname = 'on_check';
	$cntl_href = $chk_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_checkBox_HK(cname => $cname, panel_cntrls => $chk_cntl_href, font => $cbfont, col_start_x => $col_2_start_x, row_start_y => $row_3_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'checkbox', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'checkbox',
				src_name => $causal_index,
				up1_type => 'checkbox',
				up1_name => "cause",
				up2_name => "cause_n_effect",
				trace => $trace,
				);

	$cname = "perspective_view";
	$rid = 0;
	$combo_item_list = undef;
	$arr_ref = undef;
	$order_by = 'key';
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
	foreach my $c (@$arr_ref) {
		push @$combo_item_list,$c;
	}
	$rid = $self->_set_panel_comboBox_HK(cname => $cname, panel_cntrls => $combo_cntl_href, combo_item_list => $combo_item_list, id => $cntrl_id, font => $rfont, col_start_x => $col_4_start_x, row_start_y => $row_3_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'combo', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'combo',
				src_name => 'view',
				up1_type => 'text',
				up1_name => "orient",
				trace => $trace,
				);

	$cname = 'sub_role_text';
	$rid = 0;
	$evtsubname = 'on_click_submit';
	$cntl_href = $input_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	if(exists $disp_cont->{$cname}->{input_field} and $disp_cont->{$cname}->{input_field}) {
		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $input_cntl_href, font => $rfont, col_start_x => $col_6_start_x, row_start_y => $row_3_start_y, trace => $trace, );
	} else {
#		$rid = $self->_set_textCtrl_HK(cname => $cname, text_disp_cntrls => $disp_cont, panel_fields => $static_text_fields, font => $rfont,);
	}
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'input', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'text',
				src_name => 'role',
				up1_type => 'text',
				up1_name => "subrole",
				trace => $trace,
				);
	


	#############
	## ROW 4
	#############
	my $row_4_start_y = $row_3_start_y + $header_row_height;

	$cname = "cause_n_effect";
	$causal_index = 1;
	$rid = 0;
	$evtsubname = 'on_check';
	$cntl_href = $chk_cntl_href->{$cname};
	if(exists $cntl_href->{in_frame_evt_method}) {
		$evtsubname = $cntl_href->{in_frame_evt_method};
	}
	$rid = $self->_set_panel_checkBox_HK(cname => $cname, panel_cntrls => $chk_cntl_href, font => $cbfont, col_start_x => $col_2_start_x, row_start_y => $row_4_start_y, trace => $trace,);
	$_wfmgr->gui_ref_id_panel_ctrls_set_all($rid,$panel,$cname);
	$_wfmgr->panel_event_pre_set_by_wxframe(wxframe => $winframe->{WXFRAME_KEY_VALUE}, panel => $panel, type => 'checkbox', name => $cname, subname => $evtsubname);
	$_wfmgr->gui_wxapp_ctrls_sync3(
				key => $cname,
				src_type => 'checkbox',
				src_name => $causal_index,
				up1_type => 'checkbox',
				up1_name => "effect",
				up2_name => "cause",
				trace => $trace,
				);

}

no Moose; # keywords are removed from the TSCourse package

1;
