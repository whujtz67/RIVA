package vlsu_shuffle_pkg;

  // Input sequential index, output shuffle index
  // Used in Deshuffle Unit to convert sequential index to shuffle index
  function automatic logic [${clog2(riva_pkg::DLEN*riva_pkg::MaxNrLanes/4)}-1:0] query_shf_idx(input NrLanes, input int seqNbIdx, input vew_e ew);
	unique case (NrLanes)
	  1: unique case (seqNbIdx)
        0: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd0, 5'd0, 5'd0, 5'd0};
          return idx[ew];
        end
        1: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd8, 5'd1, 5'd1, 5'd1};
          return idx[ew];
        end
        2: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd16, 5'd8, 5'd2, 5'd2};
          return idx[ew];
        end
        3: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd24, 5'd9, 5'd3, 5'd3};
          return idx[ew];
        end
        4: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd4, 5'd16, 5'd8, 5'd4};
          return idx[ew];
        end
        5: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd12, 5'd17, 5'd9, 5'd5};
          return idx[ew];
        end
        6: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd20, 5'd24, 5'd10, 5'd6};
          return idx[ew];
        end
        7: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd28, 5'd25, 5'd11, 5'd7};
          return idx[ew];
        end
        8: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd2, 5'd4, 5'd16, 5'd8};
          return idx[ew];
        end
        9: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd10, 5'd5, 5'd17, 5'd9};
          return idx[ew];
        end
        10: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd18, 5'd12, 5'd18, 5'd10};
          return idx[ew];
        end
        11: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd26, 5'd13, 5'd19, 5'd11};
          return idx[ew];
        end
        12: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd6, 5'd20, 5'd24, 5'd12};
          return idx[ew];
        end
        13: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd14, 5'd21, 5'd25, 5'd13};
          return idx[ew];
        end
        14: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd22, 5'd28, 5'd26, 5'd14};
          return idx[ew];
        end
        15: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd30, 5'd29, 5'd27, 5'd15};
          return idx[ew];
        end
        16: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd1, 5'd2, 5'd4, 5'd16};
          return idx[ew];
        end
        17: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd9, 5'd3, 5'd5, 5'd17};
          return idx[ew];
        end
        18: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd17, 5'd10, 5'd6, 5'd18};
          return idx[ew];
        end
        19: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd25, 5'd11, 5'd7, 5'd19};
          return idx[ew];
        end
        20: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd5, 5'd18, 5'd12, 5'd20};
          return idx[ew];
        end
        21: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd13, 5'd19, 5'd13, 5'd21};
          return idx[ew];
        end
        22: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd21, 5'd26, 5'd14, 5'd22};
          return idx[ew];
        end
        23: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd29, 5'd27, 5'd15, 5'd23};
          return idx[ew];
        end
        24: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd3, 5'd6, 5'd20, 5'd24};
          return idx[ew];
        end
        25: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd11, 5'd7, 5'd21, 5'd25};
          return idx[ew];
        end
        26: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd19, 5'd14, 5'd22, 5'd26};
          return idx[ew];
        end
        27: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd27, 5'd15, 5'd23, 5'd27};
          return idx[ew];
        end
        28: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd7, 5'd22, 5'd28, 5'd28};
          return idx[ew];
        end
        29: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd15, 5'd23, 5'd29, 5'd29};
          return idx[ew];
        end
        30: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd23, 5'd30, 5'd30, 5'd30};
          return idx[ew];
        end
        31: begin
          automatic logic [5-1:0] idx [0:3] = '{5'd31, 5'd31, 5'd31, 5'd31};
          return idx[ew];
        end
        default: return 0;
	  endcase
	  2: unique case (seqNbIdx)
		0: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd0, 6'd0, 6'd0, 6'd0};
          return idx[ew];
        end
        1: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd32, 6'd1, 6'd1, 6'd1};
          return idx[ew];
        end
        2: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd8, 6'd32, 6'd2, 6'd2};
          return idx[ew];
        end
        3: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd40, 6'd33, 6'd3, 6'd3};
          return idx[ew];
        end
        4: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd16, 6'd8, 6'd32, 6'd4};
          return idx[ew];
        end
        5: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd48, 6'd9, 6'd33, 6'd5};
          return idx[ew];
        end
        6: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd24, 6'd40, 6'd34, 6'd6};
          return idx[ew];
        end
        7: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd56, 6'd41, 6'd35, 6'd7};
          return idx[ew];
        end
        8: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd4, 6'd16, 6'd8, 6'd32};
          return idx[ew];
        end
        9: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd36, 6'd17, 6'd9, 6'd33};
          return idx[ew];
        end
        10: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd12, 6'd48, 6'd10, 6'd34};
          return idx[ew];
        end
        11: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd44, 6'd49, 6'd11, 6'd35};
          return idx[ew];
        end
        12: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd20, 6'd24, 6'd40, 6'd36};
          return idx[ew];
        end
        13: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd52, 6'd25, 6'd41, 6'd37};
          return idx[ew];
        end
        14: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd28, 6'd56, 6'd42, 6'd38};
          return idx[ew];
        end
        15: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd60, 6'd57, 6'd43, 6'd39};
          return idx[ew];
        end
        16: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd2, 6'd4, 6'd16, 6'd8};
          return idx[ew];
        end
        17: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd34, 6'd5, 6'd17, 6'd9};
          return idx[ew];
        end
        18: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd10, 6'd36, 6'd18, 6'd10};
          return idx[ew];
        end
        19: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd42, 6'd37, 6'd19, 6'd11};
          return idx[ew];
        end
        20: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd18, 6'd12, 6'd48, 6'd12};
          return idx[ew];
        end
        21: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd50, 6'd13, 6'd49, 6'd13};
          return idx[ew];
        end
        22: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd26, 6'd44, 6'd50, 6'd14};
          return idx[ew];
        end
        23: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd58, 6'd45, 6'd51, 6'd15};
          return idx[ew];
        end
        24: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd6, 6'd20, 6'd24, 6'd40};
          return idx[ew];
        end
        25: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd38, 6'd21, 6'd25, 6'd41};
          return idx[ew];
        end
        26: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd14, 6'd52, 6'd26, 6'd42};
          return idx[ew];
        end
        27: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd46, 6'd53, 6'd27, 6'd43};
          return idx[ew];
        end
        28: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd22, 6'd28, 6'd56, 6'd44};
          return idx[ew];
        end
        29: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd54, 6'd29, 6'd57, 6'd45};
          return idx[ew];
        end
        30: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd30, 6'd60, 6'd58, 6'd46};
          return idx[ew];
        end
        31: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd62, 6'd61, 6'd59, 6'd47};
          return idx[ew];
        end
        32: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd1, 6'd2, 6'd4, 6'd16};
          return idx[ew];
        end
        33: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd33, 6'd3, 6'd5, 6'd17};
          return idx[ew];
        end
        34: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd9, 6'd34, 6'd6, 6'd18};
          return idx[ew];
        end
        35: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd41, 6'd35, 6'd7, 6'd19};
          return idx[ew];
        end
        36: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd17, 6'd10, 6'd36, 6'd20};
          return idx[ew];
        end
        37: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd49, 6'd11, 6'd37, 6'd21};
          return idx[ew];
        end
        38: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd25, 6'd42, 6'd38, 6'd22};
          return idx[ew];
        end
        39: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd57, 6'd43, 6'd39, 6'd23};
          return idx[ew];
        end
        40: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd5, 6'd18, 6'd12, 6'd48};
          return idx[ew];
        end
        41: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd37, 6'd19, 6'd13, 6'd49};
          return idx[ew];
        end
        42: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd13, 6'd50, 6'd14, 6'd50};
          return idx[ew];
        end
        43: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd45, 6'd51, 6'd15, 6'd51};
          return idx[ew];
        end
        44: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd21, 6'd26, 6'd44, 6'd52};
          return idx[ew];
        end
        45: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd53, 6'd27, 6'd45, 6'd53};
          return idx[ew];
        end
        46: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd29, 6'd58, 6'd46, 6'd54};
          return idx[ew];
        end
        47: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd61, 6'd59, 6'd47, 6'd55};
          return idx[ew];
        end
        48: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd3, 6'd6, 6'd20, 6'd24};
          return idx[ew];
        end
        49: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd35, 6'd7, 6'd21, 6'd25};
          return idx[ew];
        end
        50: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd11, 6'd38, 6'd22, 6'd26};
          return idx[ew];
        end
        51: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd43, 6'd39, 6'd23, 6'd27};
          return idx[ew];
        end
        52: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd19, 6'd14, 6'd52, 6'd28};
          return idx[ew];
        end
        53: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd51, 6'd15, 6'd53, 6'd29};
          return idx[ew];
        end
        54: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd27, 6'd46, 6'd54, 6'd30};
          return idx[ew];
        end
        55: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd59, 6'd47, 6'd55, 6'd31};
          return idx[ew];
        end
        56: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd7, 6'd22, 6'd28, 6'd56};
          return idx[ew];
        end
        57: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd39, 6'd23, 6'd29, 6'd57};
          return idx[ew];
        end
        58: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd15, 6'd54, 6'd30, 6'd58};
          return idx[ew];
        end
        59: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd47, 6'd55, 6'd31, 6'd59};
          return idx[ew];
        end
        60: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd23, 6'd30, 6'd60, 6'd60};
          return idx[ew];
        end
        61: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd55, 6'd31, 6'd61, 6'd61};
          return idx[ew];
        end
        62: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd31, 6'd62, 6'd62, 6'd62};
          return idx[ew];
        end
        63: begin
          automatic logic [6-1:0] idx [0:3] = '{6'd63, 6'd63, 6'd63, 6'd63};
          return idx[ew];
        end
    default: return 0;
	  endcase
      4: unique case (seqNbIdx)
        0: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd0, 7'd0, 7'd0, 7'd0};
          return idx[ew];
        end
        1: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd32, 7'd1, 7'd1, 7'd1};
          return idx[ew];
        end
        2: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd64, 7'd32, 7'd2, 7'd2};
          return idx[ew];
        end
        3: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd96, 7'd33, 7'd3, 7'd3};
          return idx[ew];
        end
        4: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd8, 7'd64, 7'd32, 7'd4};
          return idx[ew];
        end
        5: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd40, 7'd65, 7'd33, 7'd5};
          return idx[ew];
        end
        6: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd72, 7'd96, 7'd34, 7'd6};
          return idx[ew];
        end
        7: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd104, 7'd97, 7'd35, 7'd7};
          return idx[ew];
        end
        8: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd16, 7'd8, 7'd64, 7'd32};
          return idx[ew];
        end
        9: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd48, 7'd9, 7'd65, 7'd33};
          return idx[ew];
        end
        10: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd80, 7'd40, 7'd66, 7'd34};
          return idx[ew];
        end
        11: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd112, 7'd41, 7'd67, 7'd35};
          return idx[ew];
        end
        12: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd24, 7'd72, 7'd96, 7'd36};
          return idx[ew];
        end
        13: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd56, 7'd73, 7'd97, 7'd37};
          return idx[ew];
        end
        14: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd88, 7'd104, 7'd98, 7'd38};
          return idx[ew];
        end
        15: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd120, 7'd105, 7'd99, 7'd39};
          return idx[ew];
        end
        16: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd4, 7'd16, 7'd8, 7'd64};
          return idx[ew];
        end
        17: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd36, 7'd17, 7'd9, 7'd65};
          return idx[ew];
        end
        18: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd68, 7'd48, 7'd10, 7'd66};
          return idx[ew];
        end
        19: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd100, 7'd49, 7'd11, 7'd67};
          return idx[ew];
        end
        20: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd12, 7'd80, 7'd40, 7'd68};
          return idx[ew];
        end
        21: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd44, 7'd81, 7'd41, 7'd69};
          return idx[ew];
        end
        22: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd76, 7'd112, 7'd42, 7'd70};
          return idx[ew];
        end
        23: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd108, 7'd113, 7'd43, 7'd71};
          return idx[ew];
        end
        24: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd20, 7'd24, 7'd72, 7'd96};
          return idx[ew];
        end
        25: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd52, 7'd25, 7'd73, 7'd97};
          return idx[ew];
        end
        26: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd84, 7'd56, 7'd74, 7'd98};
          return idx[ew];
        end
        27: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd116, 7'd57, 7'd75, 7'd99};
          return idx[ew];
        end
        28: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd28, 7'd88, 7'd104, 7'd100};
          return idx[ew];
        end
        29: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd60, 7'd89, 7'd105, 7'd101};
          return idx[ew];
        end
        30: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd92, 7'd120, 7'd106, 7'd102};
          return idx[ew];
        end
        31: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd124, 7'd121, 7'd107, 7'd103};
          return idx[ew];
        end
        32: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd2, 7'd4, 7'd16, 7'd8};
          return idx[ew];
        end
        33: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd34, 7'd5, 7'd17, 7'd9};
          return idx[ew];
        end
        34: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd66, 7'd36, 7'd18, 7'd10};
          return idx[ew];
        end
        35: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd98, 7'd37, 7'd19, 7'd11};
          return idx[ew];
        end
        36: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd10, 7'd68, 7'd48, 7'd12};
          return idx[ew];
        end
        37: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd42, 7'd69, 7'd49, 7'd13};
          return idx[ew];
        end
        38: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd74, 7'd100, 7'd50, 7'd14};
          return idx[ew];
        end
        39: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd106, 7'd101, 7'd51, 7'd15};
          return idx[ew];
        end
        40: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd18, 7'd12, 7'd80, 7'd40};
          return idx[ew];
        end
        41: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd50, 7'd13, 7'd81, 7'd41};
          return idx[ew];
        end
        42: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd82, 7'd44, 7'd82, 7'd42};
          return idx[ew];
        end
        43: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd114, 7'd45, 7'd83, 7'd43};
          return idx[ew];
        end
        44: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd26, 7'd76, 7'd112, 7'd44};
          return idx[ew];
        end
        45: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd58, 7'd77, 7'd113, 7'd45};
          return idx[ew];
        end
        46: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd90, 7'd108, 7'd114, 7'd46};
          return idx[ew];
        end
        47: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd122, 7'd109, 7'd115, 7'd47};
          return idx[ew];
        end
        48: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd6, 7'd20, 7'd24, 7'd72};
          return idx[ew];
        end
        49: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd38, 7'd21, 7'd25, 7'd73};
          return idx[ew];
        end
        50: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd70, 7'd52, 7'd26, 7'd74};
          return idx[ew];
        end
        51: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd102, 7'd53, 7'd27, 7'd75};
          return idx[ew];
        end
        52: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd14, 7'd84, 7'd56, 7'd76};
          return idx[ew];
        end
        53: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd46, 7'd85, 7'd57, 7'd77};
          return idx[ew];
        end
        54: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd78, 7'd116, 7'd58, 7'd78};
          return idx[ew];
        end
        55: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd110, 7'd117, 7'd59, 7'd79};
          return idx[ew];
        end
        56: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd22, 7'd28, 7'd88, 7'd104};
          return idx[ew];
        end
        57: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd54, 7'd29, 7'd89, 7'd105};
          return idx[ew];
        end
        58: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd86, 7'd60, 7'd90, 7'd106};
          return idx[ew];
        end
        59: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd118, 7'd61, 7'd91, 7'd107};
          return idx[ew];
        end
        60: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd30, 7'd92, 7'd120, 7'd108};
          return idx[ew];
        end
        61: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd62, 7'd93, 7'd121, 7'd109};
          return idx[ew];
        end
        62: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd94, 7'd124, 7'd122, 7'd110};
          return idx[ew];
        end
        63: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd126, 7'd125, 7'd123, 7'd111};
          return idx[ew];
        end
        64: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd1, 7'd2, 7'd4, 7'd16};
          return idx[ew];
        end
        65: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd33, 7'd3, 7'd5, 7'd17};
          return idx[ew];
        end
        66: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd65, 7'd34, 7'd6, 7'd18};
          return idx[ew];
        end
        67: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd97, 7'd35, 7'd7, 7'd19};
          return idx[ew];
        end
        68: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd9, 7'd66, 7'd36, 7'd20};
          return idx[ew];
        end
        69: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd41, 7'd67, 7'd37, 7'd21};
          return idx[ew];
        end
        70: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd73, 7'd98, 7'd38, 7'd22};
          return idx[ew];
        end
        71: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd105, 7'd99, 7'd39, 7'd23};
          return idx[ew];
        end
        72: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd17, 7'd10, 7'd68, 7'd48};
          return idx[ew];
        end
        73: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd49, 7'd11, 7'd69, 7'd49};
          return idx[ew];
        end
        74: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd81, 7'd42, 7'd70, 7'd50};
          return idx[ew];
        end
        75: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd113, 7'd43, 7'd71, 7'd51};
          return idx[ew];
        end
        76: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd25, 7'd74, 7'd100, 7'd52};
          return idx[ew];
        end
        77: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd57, 7'd75, 7'd101, 7'd53};
          return idx[ew];
        end
        78: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd89, 7'd106, 7'd102, 7'd54};
          return idx[ew];
        end
        79: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd121, 7'd107, 7'd103, 7'd55};
          return idx[ew];
        end
        80: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd5, 7'd18, 7'd12, 7'd80};
          return idx[ew];
        end
        81: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd37, 7'd19, 7'd13, 7'd81};
          return idx[ew];
        end
        82: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd69, 7'd50, 7'd14, 7'd82};
          return idx[ew];
        end
        83: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd101, 7'd51, 7'd15, 7'd83};
          return idx[ew];
        end
        84: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd13, 7'd82, 7'd44, 7'd84};
          return idx[ew];
        end
        85: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd45, 7'd83, 7'd45, 7'd85};
          return idx[ew];
        end
        86: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd77, 7'd114, 7'd46, 7'd86};
          return idx[ew];
        end
        87: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd109, 7'd115, 7'd47, 7'd87};
          return idx[ew];
        end
        88: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd21, 7'd26, 7'd76, 7'd112};
          return idx[ew];
        end
        89: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd53, 7'd27, 7'd77, 7'd113};
          return idx[ew];
        end
        90: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd85, 7'd58, 7'd78, 7'd114};
          return idx[ew];
        end
        91: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd117, 7'd59, 7'd79, 7'd115};
          return idx[ew];
        end
        92: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd29, 7'd90, 7'd108, 7'd116};
          return idx[ew];
        end
        93: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd61, 7'd91, 7'd109, 7'd117};
          return idx[ew];
        end
        94: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd93, 7'd122, 7'd110, 7'd118};
          return idx[ew];
        end
        95: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd125, 7'd123, 7'd111, 7'd119};
          return idx[ew];
        end
        96: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd3, 7'd6, 7'd20, 7'd24};
          return idx[ew];
        end
        97: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd35, 7'd7, 7'd21, 7'd25};
          return idx[ew];
        end
        98: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd67, 7'd38, 7'd22, 7'd26};
          return idx[ew];
        end
        99: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd99, 7'd39, 7'd23, 7'd27};
          return idx[ew];
        end
        100: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd11, 7'd70, 7'd52, 7'd28};
          return idx[ew];
        end
        101: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd43, 7'd71, 7'd53, 7'd29};
          return idx[ew];
        end
        102: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd75, 7'd102, 7'd54, 7'd30};
          return idx[ew];
        end
        103: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd107, 7'd103, 7'd55, 7'd31};
          return idx[ew];
        end
        104: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd19, 7'd14, 7'd84, 7'd56};
          return idx[ew];
        end
        105: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd51, 7'd15, 7'd85, 7'd57};
          return idx[ew];
        end
        106: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd83, 7'd46, 7'd86, 7'd58};
          return idx[ew];
        end
        107: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd115, 7'd47, 7'd87, 7'd59};
          return idx[ew];
        end
        108: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd27, 7'd78, 7'd116, 7'd60};
          return idx[ew];
        end
        109: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd59, 7'd79, 7'd117, 7'd61};
          return idx[ew];
        end
        110: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd91, 7'd110, 7'd118, 7'd62};
          return idx[ew];
        end
        111: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd123, 7'd111, 7'd119, 7'd63};
          return idx[ew];
        end
        112: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd7, 7'd22, 7'd28, 7'd88};
          return idx[ew];
        end
        113: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd39, 7'd23, 7'd29, 7'd89};
          return idx[ew];
        end
        114: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd71, 7'd54, 7'd30, 7'd90};
          return idx[ew];
        end
        115: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd103, 7'd55, 7'd31, 7'd91};
          return idx[ew];
        end
        116: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd15, 7'd86, 7'd60, 7'd92};
          return idx[ew];
        end
        117: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd47, 7'd87, 7'd61, 7'd93};
          return idx[ew];
        end
        118: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd79, 7'd118, 7'd62, 7'd94};
          return idx[ew];
        end
        119: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd111, 7'd119, 7'd63, 7'd95};
          return idx[ew];
        end
        120: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd23, 7'd30, 7'd92, 7'd120};
          return idx[ew];
        end
        121: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd55, 7'd31, 7'd93, 7'd121};
          return idx[ew];
        end
        122: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd87, 7'd62, 7'd94, 7'd122};
          return idx[ew];
        end
        123: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd119, 7'd63, 7'd95, 7'd123};
          return idx[ew];
        end
        124: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd31, 7'd94, 7'd124, 7'd124};
          return idx[ew];
        end
        125: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd63, 7'd95, 7'd125, 7'd125};
          return idx[ew];
        end
        126: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd95, 7'd126, 7'd126, 7'd126};
          return idx[ew];
        end
        127: begin
          automatic logic [7-1:0] idx [0:3] = '{7'd127, 7'd127, 7'd127, 7'd127};
          return idx[ew];
        end
        default: return 0;
      endcase
	  8: unique case (seqNbIdx)
		0: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd0, 8'd0, 8'd0, 8'd0};
          return idx[ew];
        end
        1: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd32, 8'd1, 8'd1, 8'd1};
          return idx[ew];
        end
        2: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd64, 8'd32, 8'd2, 8'd2};
          return idx[ew];
        end
        3: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd96, 8'd33, 8'd3, 8'd3};
          return idx[ew];
        end
        4: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd128, 8'd64, 8'd32, 8'd4};
          return idx[ew];
        end
        5: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd160, 8'd65, 8'd33, 8'd5};
          return idx[ew];
        end
        6: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd192, 8'd96, 8'd34, 8'd6};
          return idx[ew];
        end
        7: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd224, 8'd97, 8'd35, 8'd7};
          return idx[ew];
        end
        8: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd8, 8'd128, 8'd64, 8'd32};
          return idx[ew];
        end
        9: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd40, 8'd129, 8'd65, 8'd33};
          return idx[ew];
        end
        10: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd72, 8'd160, 8'd66, 8'd34};
          return idx[ew];
        end
        11: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd104, 8'd161, 8'd67, 8'd35};
          return idx[ew];
        end
        12: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd136, 8'd192, 8'd96, 8'd36};
          return idx[ew];
        end
        13: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd168, 8'd193, 8'd97, 8'd37};
          return idx[ew];
        end
        14: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd200, 8'd224, 8'd98, 8'd38};
          return idx[ew];
        end
        15: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd232, 8'd225, 8'd99, 8'd39};
          return idx[ew];
        end
        16: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd16, 8'd8, 8'd128, 8'd64};
          return idx[ew];
        end
        17: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd48, 8'd9, 8'd129, 8'd65};
          return idx[ew];
        end
        18: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd80, 8'd40, 8'd130, 8'd66};
          return idx[ew];
        end
        19: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd112, 8'd41, 8'd131, 8'd67};
          return idx[ew];
        end
        20: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd144, 8'd72, 8'd160, 8'd68};
          return idx[ew];
        end
        21: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd176, 8'd73, 8'd161, 8'd69};
          return idx[ew];
        end
        22: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd208, 8'd104, 8'd162, 8'd70};
          return idx[ew];
        end
        23: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd240, 8'd105, 8'd163, 8'd71};
          return idx[ew];
        end
        24: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd24, 8'd136, 8'd192, 8'd96};
          return idx[ew];
        end
        25: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd56, 8'd137, 8'd193, 8'd97};
          return idx[ew];
        end
        26: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd88, 8'd168, 8'd194, 8'd98};
          return idx[ew];
        end
        27: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd120, 8'd169, 8'd195, 8'd99};
          return idx[ew];
        end
        28: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd152, 8'd200, 8'd224, 8'd100};
          return idx[ew];
        end
        29: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd184, 8'd201, 8'd225, 8'd101};
          return idx[ew];
        end
        30: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd216, 8'd232, 8'd226, 8'd102};
          return idx[ew];
        end
        31: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd248, 8'd233, 8'd227, 8'd103};
          return idx[ew];
        end
        32: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd4, 8'd16, 8'd8, 8'd128};
          return idx[ew];
        end
        33: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd36, 8'd17, 8'd9, 8'd129};
          return idx[ew];
        end
        34: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd68, 8'd48, 8'd10, 8'd130};
          return idx[ew];
        end
        35: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd100, 8'd49, 8'd11, 8'd131};
          return idx[ew];
        end
        36: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd132, 8'd80, 8'd40, 8'd132};
          return idx[ew];
        end
        37: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd164, 8'd81, 8'd41, 8'd133};
          return idx[ew];
        end
        38: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd196, 8'd112, 8'd42, 8'd134};
          return idx[ew];
        end
        39: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd228, 8'd113, 8'd43, 8'd135};
          return idx[ew];
        end
        40: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd12, 8'd144, 8'd72, 8'd160};
          return idx[ew];
        end
        41: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd44, 8'd145, 8'd73, 8'd161};
          return idx[ew];
        end
        42: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd76, 8'd176, 8'd74, 8'd162};
          return idx[ew];
        end
        43: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd108, 8'd177, 8'd75, 8'd163};
          return idx[ew];
        end
        44: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd140, 8'd208, 8'd104, 8'd164};
          return idx[ew];
        end
        45: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd172, 8'd209, 8'd105, 8'd165};
          return idx[ew];
        end
        46: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd204, 8'd240, 8'd106, 8'd166};
          return idx[ew];
        end
        47: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd236, 8'd241, 8'd107, 8'd167};
          return idx[ew];
        end
        48: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd20, 8'd24, 8'd136, 8'd192};
          return idx[ew];
        end
        49: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd52, 8'd25, 8'd137, 8'd193};
          return idx[ew];
        end
        50: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd84, 8'd56, 8'd138, 8'd194};
          return idx[ew];
        end
        51: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd116, 8'd57, 8'd139, 8'd195};
          return idx[ew];
        end
        52: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd148, 8'd88, 8'd168, 8'd196};
          return idx[ew];
        end
        53: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd180, 8'd89, 8'd169, 8'd197};
          return idx[ew];
        end
        54: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd212, 8'd120, 8'd170, 8'd198};
          return idx[ew];
        end
        55: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd244, 8'd121, 8'd171, 8'd199};
          return idx[ew];
        end
        56: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd28, 8'd152, 8'd200, 8'd224};
          return idx[ew];
        end
        57: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd60, 8'd153, 8'd201, 8'd225};
          return idx[ew];
        end
        58: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd92, 8'd184, 8'd202, 8'd226};
          return idx[ew];
        end
        59: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd124, 8'd185, 8'd203, 8'd227};
          return idx[ew];
        end
        60: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd156, 8'd216, 8'd232, 8'd228};
          return idx[ew];
        end
        61: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd188, 8'd217, 8'd233, 8'd229};
          return idx[ew];
        end
        62: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd220, 8'd248, 8'd234, 8'd230};
          return idx[ew];
        end
        63: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd252, 8'd249, 8'd235, 8'd231};
          return idx[ew];
        end
        64: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd2, 8'd4, 8'd16, 8'd8};
          return idx[ew];
        end
        65: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd34, 8'd5, 8'd17, 8'd9};
          return idx[ew];
        end
        66: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd66, 8'd36, 8'd18, 8'd10};
          return idx[ew];
        end
        67: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd98, 8'd37, 8'd19, 8'd11};
          return idx[ew];
        end
        68: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd130, 8'd68, 8'd48, 8'd12};
          return idx[ew];
        end
        69: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd162, 8'd69, 8'd49, 8'd13};
          return idx[ew];
        end
        70: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd194, 8'd100, 8'd50, 8'd14};
          return idx[ew];
        end
        71: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd226, 8'd101, 8'd51, 8'd15};
          return idx[ew];
        end
        72: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd10, 8'd132, 8'd80, 8'd40};
          return idx[ew];
        end
        73: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd42, 8'd133, 8'd81, 8'd41};
          return idx[ew];
        end
        74: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd74, 8'd164, 8'd82, 8'd42};
          return idx[ew];
        end
        75: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd106, 8'd165, 8'd83, 8'd43};
          return idx[ew];
        end
        76: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd138, 8'd196, 8'd112, 8'd44};
          return idx[ew];
        end
        77: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd170, 8'd197, 8'd113, 8'd45};
          return idx[ew];
        end
        78: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd202, 8'd228, 8'd114, 8'd46};
          return idx[ew];
        end
        79: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd234, 8'd229, 8'd115, 8'd47};
          return idx[ew];
        end
        80: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd18, 8'd12, 8'd144, 8'd72};
          return idx[ew];
        end
        81: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd50, 8'd13, 8'd145, 8'd73};
          return idx[ew];
        end
        82: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd82, 8'd44, 8'd146, 8'd74};
          return idx[ew];
        end
        83: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd114, 8'd45, 8'd147, 8'd75};
          return idx[ew];
        end
        84: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd146, 8'd76, 8'd176, 8'd76};
          return idx[ew];
        end
        85: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd178, 8'd77, 8'd177, 8'd77};
          return idx[ew];
        end
        86: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd210, 8'd108, 8'd178, 8'd78};
          return idx[ew];
        end
        87: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd242, 8'd109, 8'd179, 8'd79};
          return idx[ew];
        end
        88: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd26, 8'd140, 8'd208, 8'd104};
          return idx[ew];
        end
        89: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd58, 8'd141, 8'd209, 8'd105};
          return idx[ew];
        end
        90: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd90, 8'd172, 8'd210, 8'd106};
          return idx[ew];
        end
        91: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd122, 8'd173, 8'd211, 8'd107};
          return idx[ew];
        end
        92: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd154, 8'd204, 8'd240, 8'd108};
          return idx[ew];
        end
        93: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd186, 8'd205, 8'd241, 8'd109};
          return idx[ew];
        end
        94: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd218, 8'd236, 8'd242, 8'd110};
          return idx[ew];
        end
        95: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd250, 8'd237, 8'd243, 8'd111};
          return idx[ew];
        end
        96: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd6, 8'd20, 8'd24, 8'd136};
          return idx[ew];
        end
        97: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd38, 8'd21, 8'd25, 8'd137};
          return idx[ew];
        end
        98: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd70, 8'd52, 8'd26, 8'd138};
          return idx[ew];
        end
        99: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd102, 8'd53, 8'd27, 8'd139};
          return idx[ew];
        end
        100: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd134, 8'd84, 8'd56, 8'd140};
          return idx[ew];
        end
        101: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd166, 8'd85, 8'd57, 8'd141};
          return idx[ew];
        end
        102: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd198, 8'd116, 8'd58, 8'd142};
          return idx[ew];
        end
        103: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd230, 8'd117, 8'd59, 8'd143};
          return idx[ew];
        end
        104: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd14, 8'd148, 8'd88, 8'd168};
          return idx[ew];
        end
        105: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd46, 8'd149, 8'd89, 8'd169};
          return idx[ew];
        end
        106: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd78, 8'd180, 8'd90, 8'd170};
          return idx[ew];
        end
        107: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd110, 8'd181, 8'd91, 8'd171};
          return idx[ew];
        end
        108: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd142, 8'd212, 8'd120, 8'd172};
          return idx[ew];
        end
        109: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd174, 8'd213, 8'd121, 8'd173};
          return idx[ew];
        end
        110: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd206, 8'd244, 8'd122, 8'd174};
          return idx[ew];
        end
        111: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd238, 8'd245, 8'd123, 8'd175};
          return idx[ew];
        end
        112: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd22, 8'd28, 8'd152, 8'd200};
          return idx[ew];
        end
        113: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd54, 8'd29, 8'd153, 8'd201};
          return idx[ew];
        end
        114: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd86, 8'd60, 8'd154, 8'd202};
          return idx[ew];
        end
        115: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd118, 8'd61, 8'd155, 8'd203};
          return idx[ew];
        end
        116: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd150, 8'd92, 8'd184, 8'd204};
          return idx[ew];
        end
        117: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd182, 8'd93, 8'd185, 8'd205};
          return idx[ew];
        end
        118: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd214, 8'd124, 8'd186, 8'd206};
          return idx[ew];
        end
        119: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd246, 8'd125, 8'd187, 8'd207};
          return idx[ew];
        end
        120: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd30, 8'd156, 8'd216, 8'd232};
          return idx[ew];
        end
        121: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd62, 8'd157, 8'd217, 8'd233};
          return idx[ew];
        end
        122: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd94, 8'd188, 8'd218, 8'd234};
          return idx[ew];
        end
        123: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd126, 8'd189, 8'd219, 8'd235};
          return idx[ew];
        end
        124: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd158, 8'd220, 8'd248, 8'd236};
          return idx[ew];
        end
        125: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd190, 8'd221, 8'd249, 8'd237};
          return idx[ew];
        end
        126: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd222, 8'd252, 8'd250, 8'd238};
          return idx[ew];
        end
        127: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd254, 8'd253, 8'd251, 8'd239};
          return idx[ew];
        end
        128: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd1, 8'd2, 8'd4, 8'd16};
          return idx[ew];
        end
        129: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd33, 8'd3, 8'd5, 8'd17};
          return idx[ew];
        end
        130: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd65, 8'd34, 8'd6, 8'd18};
          return idx[ew];
        end
        131: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd97, 8'd35, 8'd7, 8'd19};
          return idx[ew];
        end
        132: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd129, 8'd66, 8'd36, 8'd20};
          return idx[ew];
        end
        133: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd161, 8'd67, 8'd37, 8'd21};
          return idx[ew];
        end
        134: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd193, 8'd98, 8'd38, 8'd22};
          return idx[ew];
        end
        135: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd225, 8'd99, 8'd39, 8'd23};
          return idx[ew];
        end
        136: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd9, 8'd130, 8'd68, 8'd48};
          return idx[ew];
        end
        137: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd41, 8'd131, 8'd69, 8'd49};
          return idx[ew];
        end
        138: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd73, 8'd162, 8'd70, 8'd50};
          return idx[ew];
        end
        139: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd105, 8'd163, 8'd71, 8'd51};
          return idx[ew];
        end
        140: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd137, 8'd194, 8'd100, 8'd52};
          return idx[ew];
        end
        141: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd169, 8'd195, 8'd101, 8'd53};
          return idx[ew];
        end
        142: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd201, 8'd226, 8'd102, 8'd54};
          return idx[ew];
        end
        143: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd233, 8'd227, 8'd103, 8'd55};
          return idx[ew];
        end
        144: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd17, 8'd10, 8'd132, 8'd80};
          return idx[ew];
        end
        145: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd49, 8'd11, 8'd133, 8'd81};
          return idx[ew];
        end
        146: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd81, 8'd42, 8'd134, 8'd82};
          return idx[ew];
        end
        147: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd113, 8'd43, 8'd135, 8'd83};
          return idx[ew];
        end
        148: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd145, 8'd74, 8'd164, 8'd84};
          return idx[ew];
        end
        149: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd177, 8'd75, 8'd165, 8'd85};
          return idx[ew];
        end
        150: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd209, 8'd106, 8'd166, 8'd86};
          return idx[ew];
        end
        151: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd241, 8'd107, 8'd167, 8'd87};
          return idx[ew];
        end
        152: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd25, 8'd138, 8'd196, 8'd112};
          return idx[ew];
        end
        153: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd57, 8'd139, 8'd197, 8'd113};
          return idx[ew];
        end
        154: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd89, 8'd170, 8'd198, 8'd114};
          return idx[ew];
        end
        155: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd121, 8'd171, 8'd199, 8'd115};
          return idx[ew];
        end
        156: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd153, 8'd202, 8'd228, 8'd116};
          return idx[ew];
        end
        157: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd185, 8'd203, 8'd229, 8'd117};
          return idx[ew];
        end
        158: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd217, 8'd234, 8'd230, 8'd118};
          return idx[ew];
        end
        159: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd249, 8'd235, 8'd231, 8'd119};
          return idx[ew];
        end
        160: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd5, 8'd18, 8'd12, 8'd144};
          return idx[ew];
        end
        161: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd37, 8'd19, 8'd13, 8'd145};
          return idx[ew];
        end
        162: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd69, 8'd50, 8'd14, 8'd146};
          return idx[ew];
        end
        163: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd101, 8'd51, 8'd15, 8'd147};
          return idx[ew];
        end
        164: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd133, 8'd82, 8'd44, 8'd148};
          return idx[ew];
        end
        165: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd165, 8'd83, 8'd45, 8'd149};
          return idx[ew];
        end
        166: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd197, 8'd114, 8'd46, 8'd150};
          return idx[ew];
        end
        167: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd229, 8'd115, 8'd47, 8'd151};
          return idx[ew];
        end
        168: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd13, 8'd146, 8'd76, 8'd176};
          return idx[ew];
        end
        169: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd45, 8'd147, 8'd77, 8'd177};
          return idx[ew];
        end
        170: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd77, 8'd178, 8'd78, 8'd178};
          return idx[ew];
        end
        171: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd109, 8'd179, 8'd79, 8'd179};
          return idx[ew];
        end
        172: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd141, 8'd210, 8'd108, 8'd180};
          return idx[ew];
        end
        173: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd173, 8'd211, 8'd109, 8'd181};
          return idx[ew];
        end
        174: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd205, 8'd242, 8'd110, 8'd182};
          return idx[ew];
        end
        175: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd237, 8'd243, 8'd111, 8'd183};
          return idx[ew];
        end
        176: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd21, 8'd26, 8'd140, 8'd208};
          return idx[ew];
        end
        177: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd53, 8'd27, 8'd141, 8'd209};
          return idx[ew];
        end
        178: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd85, 8'd58, 8'd142, 8'd210};
          return idx[ew];
        end
        179: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd117, 8'd59, 8'd143, 8'd211};
          return idx[ew];
        end
        180: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd149, 8'd90, 8'd172, 8'd212};
          return idx[ew];
        end
        181: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd181, 8'd91, 8'd173, 8'd213};
          return idx[ew];
        end
        182: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd213, 8'd122, 8'd174, 8'd214};
          return idx[ew];
        end
        183: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd245, 8'd123, 8'd175, 8'd215};
          return idx[ew];
        end
        184: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd29, 8'd154, 8'd204, 8'd240};
          return idx[ew];
        end
        185: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd61, 8'd155, 8'd205, 8'd241};
          return idx[ew];
        end
        186: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd93, 8'd186, 8'd206, 8'd242};
          return idx[ew];
        end
        187: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd125, 8'd187, 8'd207, 8'd243};
          return idx[ew];
        end
        188: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd157, 8'd218, 8'd236, 8'd244};
          return idx[ew];
        end
        189: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd189, 8'd219, 8'd237, 8'd245};
          return idx[ew];
        end
        190: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd221, 8'd250, 8'd238, 8'd246};
          return idx[ew];
        end
        191: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd253, 8'd251, 8'd239, 8'd247};
          return idx[ew];
        end
        192: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd3, 8'd6, 8'd20, 8'd24};
          return idx[ew];
        end
        193: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd35, 8'd7, 8'd21, 8'd25};
          return idx[ew];
        end
        194: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd67, 8'd38, 8'd22, 8'd26};
          return idx[ew];
        end
        195: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd99, 8'd39, 8'd23, 8'd27};
          return idx[ew];
        end
        196: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd131, 8'd70, 8'd52, 8'd28};
          return idx[ew];
        end
        197: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd163, 8'd71, 8'd53, 8'd29};
          return idx[ew];
        end
        198: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd195, 8'd102, 8'd54, 8'd30};
          return idx[ew];
        end
        199: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd227, 8'd103, 8'd55, 8'd31};
          return idx[ew];
        end
        200: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd11, 8'd134, 8'd84, 8'd56};
          return idx[ew];
        end
        201: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd43, 8'd135, 8'd85, 8'd57};
          return idx[ew];
        end
        202: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd75, 8'd166, 8'd86, 8'd58};
          return idx[ew];
        end
        203: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd107, 8'd167, 8'd87, 8'd59};
          return idx[ew];
        end
        204: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd139, 8'd198, 8'd116, 8'd60};
          return idx[ew];
        end
        205: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd171, 8'd199, 8'd117, 8'd61};
          return idx[ew];
        end
        206: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd203, 8'd230, 8'd118, 8'd62};
          return idx[ew];
        end
        207: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd235, 8'd231, 8'd119, 8'd63};
          return idx[ew];
        end
        208: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd19, 8'd14, 8'd148, 8'd88};
          return idx[ew];
        end
        209: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd51, 8'd15, 8'd149, 8'd89};
          return idx[ew];
        end
        210: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd83, 8'd46, 8'd150, 8'd90};
          return idx[ew];
        end
        211: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd115, 8'd47, 8'd151, 8'd91};
          return idx[ew];
        end
        212: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd147, 8'd78, 8'd180, 8'd92};
          return idx[ew];
        end
        213: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd179, 8'd79, 8'd181, 8'd93};
          return idx[ew];
        end
        214: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd211, 8'd110, 8'd182, 8'd94};
          return idx[ew];
        end
        215: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd243, 8'd111, 8'd183, 8'd95};
          return idx[ew];
        end
        216: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd27, 8'd142, 8'd212, 8'd120};
          return idx[ew];
        end
        217: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd59, 8'd143, 8'd213, 8'd121};
          return idx[ew];
        end
        218: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd91, 8'd174, 8'd214, 8'd122};
          return idx[ew];
        end
        219: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd123, 8'd175, 8'd215, 8'd123};
          return idx[ew];
        end
        220: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd155, 8'd206, 8'd244, 8'd124};
          return idx[ew];
        end
        221: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd187, 8'd207, 8'd245, 8'd125};
          return idx[ew];
        end
        222: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd219, 8'd238, 8'd246, 8'd126};
          return idx[ew];
        end
        223: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd251, 8'd239, 8'd247, 8'd127};
          return idx[ew];
        end
        224: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd7, 8'd22, 8'd28, 8'd152};
          return idx[ew];
        end
        225: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd39, 8'd23, 8'd29, 8'd153};
          return idx[ew];
        end
        226: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd71, 8'd54, 8'd30, 8'd154};
          return idx[ew];
        end
        227: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd103, 8'd55, 8'd31, 8'd155};
          return idx[ew];
        end
        228: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd135, 8'd86, 8'd60, 8'd156};
          return idx[ew];
        end
        229: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd167, 8'd87, 8'd61, 8'd157};
          return idx[ew];
        end
        230: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd199, 8'd118, 8'd62, 8'd158};
          return idx[ew];
        end
        231: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd231, 8'd119, 8'd63, 8'd159};
          return idx[ew];
        end
        232: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd15, 8'd150, 8'd92, 8'd184};
          return idx[ew];
        end
        233: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd47, 8'd151, 8'd93, 8'd185};
          return idx[ew];
        end
        234: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd79, 8'd182, 8'd94, 8'd186};
          return idx[ew];
        end
        235: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd111, 8'd183, 8'd95, 8'd187};
          return idx[ew];
        end
        236: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd143, 8'd214, 8'd124, 8'd188};
          return idx[ew];
        end
        237: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd175, 8'd215, 8'd125, 8'd189};
          return idx[ew];
        end
        238: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd207, 8'd246, 8'd126, 8'd190};
          return idx[ew];
        end
        239: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd239, 8'd247, 8'd127, 8'd191};
          return idx[ew];
        end
        240: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd23, 8'd30, 8'd156, 8'd216};
          return idx[ew];
        end
        241: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd55, 8'd31, 8'd157, 8'd217};
          return idx[ew];
        end
        242: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd87, 8'd62, 8'd158, 8'd218};
          return idx[ew];
        end
        243: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd119, 8'd63, 8'd159, 8'd219};
          return idx[ew];
        end
        244: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd151, 8'd94, 8'd188, 8'd220};
          return idx[ew];
        end
        245: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd183, 8'd95, 8'd189, 8'd221};
          return idx[ew];
        end
        246: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd215, 8'd126, 8'd190, 8'd222};
          return idx[ew];
        end
        247: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd247, 8'd127, 8'd191, 8'd223};
          return idx[ew];
        end
        248: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd31, 8'd158, 8'd220, 8'd248};
          return idx[ew];
        end
        249: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd63, 8'd159, 8'd221, 8'd249};
          return idx[ew];
        end
        250: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd95, 8'd190, 8'd222, 8'd250};
          return idx[ew];
        end
        251: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd127, 8'd191, 8'd223, 8'd251};
          return idx[ew];
        end
        252: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd159, 8'd222, 8'd252, 8'd252};
          return idx[ew];
        end
        253: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd191, 8'd223, 8'd253, 8'd253};
          return idx[ew];
        end
        254: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd223, 8'd254, 8'd254, 8'd254};
          return idx[ew];
        end
        255: begin
          automatic logic [8-1:0] idx [0:3] = '{8'd255, 8'd255, 8'd255, 8'd255};
          return idx[ew];
        end
    default: return 0;
	  endcase
	  16: unique case (seqNbIdx)
		0: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd0, 9'd0, 9'd0, 9'd0};
          return idx[ew];
        end
        1: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd32, 9'd1, 9'd1, 9'd1};
          return idx[ew];
        end
        2: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd64, 9'd32, 9'd2, 9'd2};
          return idx[ew];
        end
        3: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd96, 9'd33, 9'd3, 9'd3};
          return idx[ew];
        end
        4: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd128, 9'd64, 9'd32, 9'd4};
          return idx[ew];
        end
        5: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd160, 9'd65, 9'd33, 9'd5};
          return idx[ew];
        end
        6: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd192, 9'd96, 9'd34, 9'd6};
          return idx[ew];
        end
        7: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd224, 9'd97, 9'd35, 9'd7};
          return idx[ew];
        end
        8: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd256, 9'd128, 9'd64, 9'd32};
          return idx[ew];
        end
        9: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd288, 9'd129, 9'd65, 9'd33};
          return idx[ew];
        end
        10: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd320, 9'd160, 9'd66, 9'd34};
          return idx[ew];
        end
        11: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd352, 9'd161, 9'd67, 9'd35};
          return idx[ew];
        end
        12: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd384, 9'd192, 9'd96, 9'd36};
          return idx[ew];
        end
        13: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd416, 9'd193, 9'd97, 9'd37};
          return idx[ew];
        end
        14: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd448, 9'd224, 9'd98, 9'd38};
          return idx[ew];
        end
        15: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd480, 9'd225, 9'd99, 9'd39};
          return idx[ew];
        end
        16: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd8, 9'd256, 9'd128, 9'd64};
          return idx[ew];
        end
        17: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd40, 9'd257, 9'd129, 9'd65};
          return idx[ew];
        end
        18: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd72, 9'd288, 9'd130, 9'd66};
          return idx[ew];
        end
        19: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd104, 9'd289, 9'd131, 9'd67};
          return idx[ew];
        end
        20: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd136, 9'd320, 9'd160, 9'd68};
          return idx[ew];
        end
        21: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd168, 9'd321, 9'd161, 9'd69};
          return idx[ew];
        end
        22: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd200, 9'd352, 9'd162, 9'd70};
          return idx[ew];
        end
        23: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd232, 9'd353, 9'd163, 9'd71};
          return idx[ew];
        end
        24: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd264, 9'd384, 9'd192, 9'd96};
          return idx[ew];
        end
        25: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd296, 9'd385, 9'd193, 9'd97};
          return idx[ew];
        end
        26: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd328, 9'd416, 9'd194, 9'd98};
          return idx[ew];
        end
        27: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd360, 9'd417, 9'd195, 9'd99};
          return idx[ew];
        end
        28: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd392, 9'd448, 9'd224, 9'd100};
          return idx[ew];
        end
        29: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd424, 9'd449, 9'd225, 9'd101};
          return idx[ew];
        end
        30: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd456, 9'd480, 9'd226, 9'd102};
          return idx[ew];
        end
        31: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd488, 9'd481, 9'd227, 9'd103};
          return idx[ew];
        end
        32: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd16, 9'd8, 9'd256, 9'd128};
          return idx[ew];
        end
        33: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd48, 9'd9, 9'd257, 9'd129};
          return idx[ew];
        end
        34: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd80, 9'd40, 9'd258, 9'd130};
          return idx[ew];
        end
        35: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd112, 9'd41, 9'd259, 9'd131};
          return idx[ew];
        end
        36: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd144, 9'd72, 9'd288, 9'd132};
          return idx[ew];
        end
        37: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd176, 9'd73, 9'd289, 9'd133};
          return idx[ew];
        end
        38: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd208, 9'd104, 9'd290, 9'd134};
          return idx[ew];
        end
        39: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd240, 9'd105, 9'd291, 9'd135};
          return idx[ew];
        end
        40: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd272, 9'd136, 9'd320, 9'd160};
          return idx[ew];
        end
        41: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd304, 9'd137, 9'd321, 9'd161};
          return idx[ew];
        end
        42: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd336, 9'd168, 9'd322, 9'd162};
          return idx[ew];
        end
        43: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd368, 9'd169, 9'd323, 9'd163};
          return idx[ew];
        end
        44: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd400, 9'd200, 9'd352, 9'd164};
          return idx[ew];
        end
        45: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd432, 9'd201, 9'd353, 9'd165};
          return idx[ew];
        end
        46: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd464, 9'd232, 9'd354, 9'd166};
          return idx[ew];
        end
        47: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd496, 9'd233, 9'd355, 9'd167};
          return idx[ew];
        end
        48: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd24, 9'd264, 9'd384, 9'd192};
          return idx[ew];
        end
        49: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd56, 9'd265, 9'd385, 9'd193};
          return idx[ew];
        end
        50: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd88, 9'd296, 9'd386, 9'd194};
          return idx[ew];
        end
        51: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd120, 9'd297, 9'd387, 9'd195};
          return idx[ew];
        end
        52: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd152, 9'd328, 9'd416, 9'd196};
          return idx[ew];
        end
        53: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd184, 9'd329, 9'd417, 9'd197};
          return idx[ew];
        end
        54: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd216, 9'd360, 9'd418, 9'd198};
          return idx[ew];
        end
        55: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd248, 9'd361, 9'd419, 9'd199};
          return idx[ew];
        end
        56: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd280, 9'd392, 9'd448, 9'd224};
          return idx[ew];
        end
        57: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd312, 9'd393, 9'd449, 9'd225};
          return idx[ew];
        end
        58: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd344, 9'd424, 9'd450, 9'd226};
          return idx[ew];
        end
        59: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd376, 9'd425, 9'd451, 9'd227};
          return idx[ew];
        end
        60: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd408, 9'd456, 9'd480, 9'd228};
          return idx[ew];
        end
        61: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd440, 9'd457, 9'd481, 9'd229};
          return idx[ew];
        end
        62: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd472, 9'd488, 9'd482, 9'd230};
          return idx[ew];
        end
        63: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd504, 9'd489, 9'd483, 9'd231};
          return idx[ew];
        end
        64: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd4, 9'd16, 9'd8, 9'd256};
          return idx[ew];
        end
        65: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd36, 9'd17, 9'd9, 9'd257};
          return idx[ew];
        end
        66: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd68, 9'd48, 9'd10, 9'd258};
          return idx[ew];
        end
        67: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd100, 9'd49, 9'd11, 9'd259};
          return idx[ew];
        end
        68: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd132, 9'd80, 9'd40, 9'd260};
          return idx[ew];
        end
        69: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd164, 9'd81, 9'd41, 9'd261};
          return idx[ew];
        end
        70: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd196, 9'd112, 9'd42, 9'd262};
          return idx[ew];
        end
        71: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd228, 9'd113, 9'd43, 9'd263};
          return idx[ew];
        end
        72: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd260, 9'd144, 9'd72, 9'd288};
          return idx[ew];
        end
        73: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd292, 9'd145, 9'd73, 9'd289};
          return idx[ew];
        end
        74: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd324, 9'd176, 9'd74, 9'd290};
          return idx[ew];
        end
        75: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd356, 9'd177, 9'd75, 9'd291};
          return idx[ew];
        end
        76: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd388, 9'd208, 9'd104, 9'd292};
          return idx[ew];
        end
        77: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd420, 9'd209, 9'd105, 9'd293};
          return idx[ew];
        end
        78: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd452, 9'd240, 9'd106, 9'd294};
          return idx[ew];
        end
        79: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd484, 9'd241, 9'd107, 9'd295};
          return idx[ew];
        end
        80: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd12, 9'd272, 9'd136, 9'd320};
          return idx[ew];
        end
        81: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd44, 9'd273, 9'd137, 9'd321};
          return idx[ew];
        end
        82: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd76, 9'd304, 9'd138, 9'd322};
          return idx[ew];
        end
        83: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd108, 9'd305, 9'd139, 9'd323};
          return idx[ew];
        end
        84: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd140, 9'd336, 9'd168, 9'd324};
          return idx[ew];
        end
        85: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd172, 9'd337, 9'd169, 9'd325};
          return idx[ew];
        end
        86: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd204, 9'd368, 9'd170, 9'd326};
          return idx[ew];
        end
        87: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd236, 9'd369, 9'd171, 9'd327};
          return idx[ew];
        end
        88: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd268, 9'd400, 9'd200, 9'd352};
          return idx[ew];
        end
        89: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd300, 9'd401, 9'd201, 9'd353};
          return idx[ew];
        end
        90: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd332, 9'd432, 9'd202, 9'd354};
          return idx[ew];
        end
        91: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd364, 9'd433, 9'd203, 9'd355};
          return idx[ew];
        end
        92: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd396, 9'd464, 9'd232, 9'd356};
          return idx[ew];
        end
        93: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd428, 9'd465, 9'd233, 9'd357};
          return idx[ew];
        end
        94: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd460, 9'd496, 9'd234, 9'd358};
          return idx[ew];
        end
        95: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd492, 9'd497, 9'd235, 9'd359};
          return idx[ew];
        end
        96: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd20, 9'd24, 9'd264, 9'd384};
          return idx[ew];
        end
        97: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd52, 9'd25, 9'd265, 9'd385};
          return idx[ew];
        end
        98: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd84, 9'd56, 9'd266, 9'd386};
          return idx[ew];
        end
        99: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd116, 9'd57, 9'd267, 9'd387};
          return idx[ew];
        end
        100: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd148, 9'd88, 9'd296, 9'd388};
          return idx[ew];
        end
        101: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd180, 9'd89, 9'd297, 9'd389};
          return idx[ew];
        end
        102: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd212, 9'd120, 9'd298, 9'd390};
          return idx[ew];
        end
        103: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd244, 9'd121, 9'd299, 9'd391};
          return idx[ew];
        end
        104: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd276, 9'd152, 9'd328, 9'd416};
          return idx[ew];
        end
        105: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd308, 9'd153, 9'd329, 9'd417};
          return idx[ew];
        end
        106: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd340, 9'd184, 9'd330, 9'd418};
          return idx[ew];
        end
        107: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd372, 9'd185, 9'd331, 9'd419};
          return idx[ew];
        end
        108: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd404, 9'd216, 9'd360, 9'd420};
          return idx[ew];
        end
        109: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd436, 9'd217, 9'd361, 9'd421};
          return idx[ew];
        end
        110: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd468, 9'd248, 9'd362, 9'd422};
          return idx[ew];
        end
        111: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd500, 9'd249, 9'd363, 9'd423};
          return idx[ew];
        end
        112: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd28, 9'd280, 9'd392, 9'd448};
          return idx[ew];
        end
        113: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd60, 9'd281, 9'd393, 9'd449};
          return idx[ew];
        end
        114: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd92, 9'd312, 9'd394, 9'd450};
          return idx[ew];
        end
        115: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd124, 9'd313, 9'd395, 9'd451};
          return idx[ew];
        end
        116: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd156, 9'd344, 9'd424, 9'd452};
          return idx[ew];
        end
        117: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd188, 9'd345, 9'd425, 9'd453};
          return idx[ew];
        end
        118: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd220, 9'd376, 9'd426, 9'd454};
          return idx[ew];
        end
        119: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd252, 9'd377, 9'd427, 9'd455};
          return idx[ew];
        end
        120: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd284, 9'd408, 9'd456, 9'd480};
          return idx[ew];
        end
        121: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd316, 9'd409, 9'd457, 9'd481};
          return idx[ew];
        end
        122: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd348, 9'd440, 9'd458, 9'd482};
          return idx[ew];
        end
        123: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd380, 9'd441, 9'd459, 9'd483};
          return idx[ew];
        end
        124: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd412, 9'd472, 9'd488, 9'd484};
          return idx[ew];
        end
        125: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd444, 9'd473, 9'd489, 9'd485};
          return idx[ew];
        end
        126: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd476, 9'd504, 9'd490, 9'd486};
          return idx[ew];
        end
        127: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd508, 9'd505, 9'd491, 9'd487};
          return idx[ew];
        end
        128: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd2, 9'd4, 9'd16, 9'd8};
          return idx[ew];
        end
        129: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd34, 9'd5, 9'd17, 9'd9};
          return idx[ew];
        end
        130: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd66, 9'd36, 9'd18, 9'd10};
          return idx[ew];
        end
        131: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd98, 9'd37, 9'd19, 9'd11};
          return idx[ew];
        end
        132: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd130, 9'd68, 9'd48, 9'd12};
          return idx[ew];
        end
        133: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd162, 9'd69, 9'd49, 9'd13};
          return idx[ew];
        end
        134: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd194, 9'd100, 9'd50, 9'd14};
          return idx[ew];
        end
        135: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd226, 9'd101, 9'd51, 9'd15};
          return idx[ew];
        end
        136: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd258, 9'd132, 9'd80, 9'd40};
          return idx[ew];
        end
        137: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd290, 9'd133, 9'd81, 9'd41};
          return idx[ew];
        end
        138: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd322, 9'd164, 9'd82, 9'd42};
          return idx[ew];
        end
        139: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd354, 9'd165, 9'd83, 9'd43};
          return idx[ew];
        end
        140: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd386, 9'd196, 9'd112, 9'd44};
          return idx[ew];
        end
        141: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd418, 9'd197, 9'd113, 9'd45};
          return idx[ew];
        end
        142: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd450, 9'd228, 9'd114, 9'd46};
          return idx[ew];
        end
        143: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd482, 9'd229, 9'd115, 9'd47};
          return idx[ew];
        end
        144: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd10, 9'd260, 9'd144, 9'd72};
          return idx[ew];
        end
        145: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd42, 9'd261, 9'd145, 9'd73};
          return idx[ew];
        end
        146: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd74, 9'd292, 9'd146, 9'd74};
          return idx[ew];
        end
        147: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd106, 9'd293, 9'd147, 9'd75};
          return idx[ew];
        end
        148: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd138, 9'd324, 9'd176, 9'd76};
          return idx[ew];
        end
        149: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd170, 9'd325, 9'd177, 9'd77};
          return idx[ew];
        end
        150: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd202, 9'd356, 9'd178, 9'd78};
          return idx[ew];
        end
        151: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd234, 9'd357, 9'd179, 9'd79};
          return idx[ew];
        end
        152: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd266, 9'd388, 9'd208, 9'd104};
          return idx[ew];
        end
        153: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd298, 9'd389, 9'd209, 9'd105};
          return idx[ew];
        end
        154: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd330, 9'd420, 9'd210, 9'd106};
          return idx[ew];
        end
        155: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd362, 9'd421, 9'd211, 9'd107};
          return idx[ew];
        end
        156: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd394, 9'd452, 9'd240, 9'd108};
          return idx[ew];
        end
        157: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd426, 9'd453, 9'd241, 9'd109};
          return idx[ew];
        end
        158: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd458, 9'd484, 9'd242, 9'd110};
          return idx[ew];
        end
        159: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd490, 9'd485, 9'd243, 9'd111};
          return idx[ew];
        end
        160: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd18, 9'd12, 9'd272, 9'd136};
          return idx[ew];
        end
        161: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd50, 9'd13, 9'd273, 9'd137};
          return idx[ew];
        end
        162: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd82, 9'd44, 9'd274, 9'd138};
          return idx[ew];
        end
        163: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd114, 9'd45, 9'd275, 9'd139};
          return idx[ew];
        end
        164: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd146, 9'd76, 9'd304, 9'd140};
          return idx[ew];
        end
        165: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd178, 9'd77, 9'd305, 9'd141};
          return idx[ew];
        end
        166: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd210, 9'd108, 9'd306, 9'd142};
          return idx[ew];
        end
        167: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd242, 9'd109, 9'd307, 9'd143};
          return idx[ew];
        end
        168: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd274, 9'd140, 9'd336, 9'd168};
          return idx[ew];
        end
        169: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd306, 9'd141, 9'd337, 9'd169};
          return idx[ew];
        end
        170: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd338, 9'd172, 9'd338, 9'd170};
          return idx[ew];
        end
        171: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd370, 9'd173, 9'd339, 9'd171};
          return idx[ew];
        end
        172: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd402, 9'd204, 9'd368, 9'd172};
          return idx[ew];
        end
        173: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd434, 9'd205, 9'd369, 9'd173};
          return idx[ew];
        end
        174: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd466, 9'd236, 9'd370, 9'd174};
          return idx[ew];
        end
        175: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd498, 9'd237, 9'd371, 9'd175};
          return idx[ew];
        end
        176: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd26, 9'd268, 9'd400, 9'd200};
          return idx[ew];
        end
        177: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd58, 9'd269, 9'd401, 9'd201};
          return idx[ew];
        end
        178: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd90, 9'd300, 9'd402, 9'd202};
          return idx[ew];
        end
        179: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd122, 9'd301, 9'd403, 9'd203};
          return idx[ew];
        end
        180: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd154, 9'd332, 9'd432, 9'd204};
          return idx[ew];
        end
        181: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd186, 9'd333, 9'd433, 9'd205};
          return idx[ew];
        end
        182: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd218, 9'd364, 9'd434, 9'd206};
          return idx[ew];
        end
        183: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd250, 9'd365, 9'd435, 9'd207};
          return idx[ew];
        end
        184: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd282, 9'd396, 9'd464, 9'd232};
          return idx[ew];
        end
        185: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd314, 9'd397, 9'd465, 9'd233};
          return idx[ew];
        end
        186: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd346, 9'd428, 9'd466, 9'd234};
          return idx[ew];
        end
        187: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd378, 9'd429, 9'd467, 9'd235};
          return idx[ew];
        end
        188: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd410, 9'd460, 9'd496, 9'd236};
          return idx[ew];
        end
        189: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd442, 9'd461, 9'd497, 9'd237};
          return idx[ew];
        end
        190: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd474, 9'd492, 9'd498, 9'd238};
          return idx[ew];
        end
        191: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd506, 9'd493, 9'd499, 9'd239};
          return idx[ew];
        end
        192: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd6, 9'd20, 9'd24, 9'd264};
          return idx[ew];
        end
        193: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd38, 9'd21, 9'd25, 9'd265};
          return idx[ew];
        end
        194: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd70, 9'd52, 9'd26, 9'd266};
          return idx[ew];
        end
        195: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd102, 9'd53, 9'd27, 9'd267};
          return idx[ew];
        end
        196: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd134, 9'd84, 9'd56, 9'd268};
          return idx[ew];
        end
        197: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd166, 9'd85, 9'd57, 9'd269};
          return idx[ew];
        end
        198: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd198, 9'd116, 9'd58, 9'd270};
          return idx[ew];
        end
        199: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd230, 9'd117, 9'd59, 9'd271};
          return idx[ew];
        end
        200: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd262, 9'd148, 9'd88, 9'd296};
          return idx[ew];
        end
        201: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd294, 9'd149, 9'd89, 9'd297};
          return idx[ew];
        end
        202: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd326, 9'd180, 9'd90, 9'd298};
          return idx[ew];
        end
        203: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd358, 9'd181, 9'd91, 9'd299};
          return idx[ew];
        end
        204: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd390, 9'd212, 9'd120, 9'd300};
          return idx[ew];
        end
        205: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd422, 9'd213, 9'd121, 9'd301};
          return idx[ew];
        end
        206: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd454, 9'd244, 9'd122, 9'd302};
          return idx[ew];
        end
        207: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd486, 9'd245, 9'd123, 9'd303};
          return idx[ew];
        end
        208: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd14, 9'd276, 9'd152, 9'd328};
          return idx[ew];
        end
        209: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd46, 9'd277, 9'd153, 9'd329};
          return idx[ew];
        end
        210: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd78, 9'd308, 9'd154, 9'd330};
          return idx[ew];
        end
        211: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd110, 9'd309, 9'd155, 9'd331};
          return idx[ew];
        end
        212: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd142, 9'd340, 9'd184, 9'd332};
          return idx[ew];
        end
        213: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd174, 9'd341, 9'd185, 9'd333};
          return idx[ew];
        end
        214: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd206, 9'd372, 9'd186, 9'd334};
          return idx[ew];
        end
        215: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd238, 9'd373, 9'd187, 9'd335};
          return idx[ew];
        end
        216: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd270, 9'd404, 9'd216, 9'd360};
          return idx[ew];
        end
        217: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd302, 9'd405, 9'd217, 9'd361};
          return idx[ew];
        end
        218: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd334, 9'd436, 9'd218, 9'd362};
          return idx[ew];
        end
        219: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd366, 9'd437, 9'd219, 9'd363};
          return idx[ew];
        end
        220: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd398, 9'd468, 9'd248, 9'd364};
          return idx[ew];
        end
        221: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd430, 9'd469, 9'd249, 9'd365};
          return idx[ew];
        end
        222: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd462, 9'd500, 9'd250, 9'd366};
          return idx[ew];
        end
        223: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd494, 9'd501, 9'd251, 9'd367};
          return idx[ew];
        end
        224: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd22, 9'd28, 9'd280, 9'd392};
          return idx[ew];
        end
        225: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd54, 9'd29, 9'd281, 9'd393};
          return idx[ew];
        end
        226: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd86, 9'd60, 9'd282, 9'd394};
          return idx[ew];
        end
        227: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd118, 9'd61, 9'd283, 9'd395};
          return idx[ew];
        end
        228: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd150, 9'd92, 9'd312, 9'd396};
          return idx[ew];
        end
        229: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd182, 9'd93, 9'd313, 9'd397};
          return idx[ew];
        end
        230: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd214, 9'd124, 9'd314, 9'd398};
          return idx[ew];
        end
        231: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd246, 9'd125, 9'd315, 9'd399};
          return idx[ew];
        end
        232: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd278, 9'd156, 9'd344, 9'd424};
          return idx[ew];
        end
        233: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd310, 9'd157, 9'd345, 9'd425};
          return idx[ew];
        end
        234: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd342, 9'd188, 9'd346, 9'd426};
          return idx[ew];
        end
        235: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd374, 9'd189, 9'd347, 9'd427};
          return idx[ew];
        end
        236: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd406, 9'd220, 9'd376, 9'd428};
          return idx[ew];
        end
        237: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd438, 9'd221, 9'd377, 9'd429};
          return idx[ew];
        end
        238: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd470, 9'd252, 9'd378, 9'd430};
          return idx[ew];
        end
        239: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd502, 9'd253, 9'd379, 9'd431};
          return idx[ew];
        end
        240: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd30, 9'd284, 9'd408, 9'd456};
          return idx[ew];
        end
        241: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd62, 9'd285, 9'd409, 9'd457};
          return idx[ew];
        end
        242: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd94, 9'd316, 9'd410, 9'd458};
          return idx[ew];
        end
        243: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd126, 9'd317, 9'd411, 9'd459};
          return idx[ew];
        end
        244: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd158, 9'd348, 9'd440, 9'd460};
          return idx[ew];
        end
        245: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd190, 9'd349, 9'd441, 9'd461};
          return idx[ew];
        end
        246: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd222, 9'd380, 9'd442, 9'd462};
          return idx[ew];
        end
        247: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd254, 9'd381, 9'd443, 9'd463};
          return idx[ew];
        end
        248: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd286, 9'd412, 9'd472, 9'd488};
          return idx[ew];
        end
        249: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd318, 9'd413, 9'd473, 9'd489};
          return idx[ew];
        end
        250: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd350, 9'd444, 9'd474, 9'd490};
          return idx[ew];
        end
        251: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd382, 9'd445, 9'd475, 9'd491};
          return idx[ew];
        end
        252: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd414, 9'd476, 9'd504, 9'd492};
          return idx[ew];
        end
        253: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd446, 9'd477, 9'd505, 9'd493};
          return idx[ew];
        end
        254: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd478, 9'd508, 9'd506, 9'd494};
          return idx[ew];
        end
        255: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd510, 9'd509, 9'd507, 9'd495};
          return idx[ew];
        end
        256: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd1, 9'd2, 9'd4, 9'd16};
          return idx[ew];
        end
        257: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd33, 9'd3, 9'd5, 9'd17};
          return idx[ew];
        end
        258: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd65, 9'd34, 9'd6, 9'd18};
          return idx[ew];
        end
        259: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd97, 9'd35, 9'd7, 9'd19};
          return idx[ew];
        end
        260: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd129, 9'd66, 9'd36, 9'd20};
          return idx[ew];
        end
        261: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd161, 9'd67, 9'd37, 9'd21};
          return idx[ew];
        end
        262: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd193, 9'd98, 9'd38, 9'd22};
          return idx[ew];
        end
        263: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd225, 9'd99, 9'd39, 9'd23};
          return idx[ew];
        end
        264: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd257, 9'd130, 9'd68, 9'd48};
          return idx[ew];
        end
        265: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd289, 9'd131, 9'd69, 9'd49};
          return idx[ew];
        end
        266: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd321, 9'd162, 9'd70, 9'd50};
          return idx[ew];
        end
        267: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd353, 9'd163, 9'd71, 9'd51};
          return idx[ew];
        end
        268: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd385, 9'd194, 9'd100, 9'd52};
          return idx[ew];
        end
        269: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd417, 9'd195, 9'd101, 9'd53};
          return idx[ew];
        end
        270: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd449, 9'd226, 9'd102, 9'd54};
          return idx[ew];
        end
        271: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd481, 9'd227, 9'd103, 9'd55};
          return idx[ew];
        end
        272: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd9, 9'd258, 9'd132, 9'd80};
          return idx[ew];
        end
        273: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd41, 9'd259, 9'd133, 9'd81};
          return idx[ew];
        end
        274: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd73, 9'd290, 9'd134, 9'd82};
          return idx[ew];
        end
        275: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd105, 9'd291, 9'd135, 9'd83};
          return idx[ew];
        end
        276: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd137, 9'd322, 9'd164, 9'd84};
          return idx[ew];
        end
        277: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd169, 9'd323, 9'd165, 9'd85};
          return idx[ew];
        end
        278: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd201, 9'd354, 9'd166, 9'd86};
          return idx[ew];
        end
        279: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd233, 9'd355, 9'd167, 9'd87};
          return idx[ew];
        end
        280: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd265, 9'd386, 9'd196, 9'd112};
          return idx[ew];
        end
        281: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd297, 9'd387, 9'd197, 9'd113};
          return idx[ew];
        end
        282: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd329, 9'd418, 9'd198, 9'd114};
          return idx[ew];
        end
        283: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd361, 9'd419, 9'd199, 9'd115};
          return idx[ew];
        end
        284: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd393, 9'd450, 9'd228, 9'd116};
          return idx[ew];
        end
        285: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd425, 9'd451, 9'd229, 9'd117};
          return idx[ew];
        end
        286: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd457, 9'd482, 9'd230, 9'd118};
          return idx[ew];
        end
        287: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd489, 9'd483, 9'd231, 9'd119};
          return idx[ew];
        end
        288: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd17, 9'd10, 9'd260, 9'd144};
          return idx[ew];
        end
        289: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd49, 9'd11, 9'd261, 9'd145};
          return idx[ew];
        end
        290: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd81, 9'd42, 9'd262, 9'd146};
          return idx[ew];
        end
        291: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd113, 9'd43, 9'd263, 9'd147};
          return idx[ew];
        end
        292: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd145, 9'd74, 9'd292, 9'd148};
          return idx[ew];
        end
        293: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd177, 9'd75, 9'd293, 9'd149};
          return idx[ew];
        end
        294: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd209, 9'd106, 9'd294, 9'd150};
          return idx[ew];
        end
        295: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd241, 9'd107, 9'd295, 9'd151};
          return idx[ew];
        end
        296: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd273, 9'd138, 9'd324, 9'd176};
          return idx[ew];
        end
        297: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd305, 9'd139, 9'd325, 9'd177};
          return idx[ew];
        end
        298: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd337, 9'd170, 9'd326, 9'd178};
          return idx[ew];
        end
        299: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd369, 9'd171, 9'd327, 9'd179};
          return idx[ew];
        end
        300: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd401, 9'd202, 9'd356, 9'd180};
          return idx[ew];
        end
        301: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd433, 9'd203, 9'd357, 9'd181};
          return idx[ew];
        end
        302: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd465, 9'd234, 9'd358, 9'd182};
          return idx[ew];
        end
        303: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd497, 9'd235, 9'd359, 9'd183};
          return idx[ew];
        end
        304: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd25, 9'd266, 9'd388, 9'd208};
          return idx[ew];
        end
        305: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd57, 9'd267, 9'd389, 9'd209};
          return idx[ew];
        end
        306: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd89, 9'd298, 9'd390, 9'd210};
          return idx[ew];
        end
        307: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd121, 9'd299, 9'd391, 9'd211};
          return idx[ew];
        end
        308: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd153, 9'd330, 9'd420, 9'd212};
          return idx[ew];
        end
        309: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd185, 9'd331, 9'd421, 9'd213};
          return idx[ew];
        end
        310: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd217, 9'd362, 9'd422, 9'd214};
          return idx[ew];
        end
        311: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd249, 9'd363, 9'd423, 9'd215};
          return idx[ew];
        end
        312: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd281, 9'd394, 9'd452, 9'd240};
          return idx[ew];
        end
        313: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd313, 9'd395, 9'd453, 9'd241};
          return idx[ew];
        end
        314: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd345, 9'd426, 9'd454, 9'd242};
          return idx[ew];
        end
        315: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd377, 9'd427, 9'd455, 9'd243};
          return idx[ew];
        end
        316: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd409, 9'd458, 9'd484, 9'd244};
          return idx[ew];
        end
        317: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd441, 9'd459, 9'd485, 9'd245};
          return idx[ew];
        end
        318: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd473, 9'd490, 9'd486, 9'd246};
          return idx[ew];
        end
        319: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd505, 9'd491, 9'd487, 9'd247};
          return idx[ew];
        end
        320: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd5, 9'd18, 9'd12, 9'd272};
          return idx[ew];
        end
        321: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd37, 9'd19, 9'd13, 9'd273};
          return idx[ew];
        end
        322: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd69, 9'd50, 9'd14, 9'd274};
          return idx[ew];
        end
        323: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd101, 9'd51, 9'd15, 9'd275};
          return idx[ew];
        end
        324: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd133, 9'd82, 9'd44, 9'd276};
          return idx[ew];
        end
        325: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd165, 9'd83, 9'd45, 9'd277};
          return idx[ew];
        end
        326: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd197, 9'd114, 9'd46, 9'd278};
          return idx[ew];
        end
        327: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd229, 9'd115, 9'd47, 9'd279};
          return idx[ew];
        end
        328: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd261, 9'd146, 9'd76, 9'd304};
          return idx[ew];
        end
        329: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd293, 9'd147, 9'd77, 9'd305};
          return idx[ew];
        end
        330: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd325, 9'd178, 9'd78, 9'd306};
          return idx[ew];
        end
        331: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd357, 9'd179, 9'd79, 9'd307};
          return idx[ew];
        end
        332: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd389, 9'd210, 9'd108, 9'd308};
          return idx[ew];
        end
        333: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd421, 9'd211, 9'd109, 9'd309};
          return idx[ew];
        end
        334: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd453, 9'd242, 9'd110, 9'd310};
          return idx[ew];
        end
        335: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd485, 9'd243, 9'd111, 9'd311};
          return idx[ew];
        end
        336: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd13, 9'd274, 9'd140, 9'd336};
          return idx[ew];
        end
        337: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd45, 9'd275, 9'd141, 9'd337};
          return idx[ew];
        end
        338: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd77, 9'd306, 9'd142, 9'd338};
          return idx[ew];
        end
        339: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd109, 9'd307, 9'd143, 9'd339};
          return idx[ew];
        end
        340: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd141, 9'd338, 9'd172, 9'd340};
          return idx[ew];
        end
        341: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd173, 9'd339, 9'd173, 9'd341};
          return idx[ew];
        end
        342: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd205, 9'd370, 9'd174, 9'd342};
          return idx[ew];
        end
        343: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd237, 9'd371, 9'd175, 9'd343};
          return idx[ew];
        end
        344: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd269, 9'd402, 9'd204, 9'd368};
          return idx[ew];
        end
        345: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd301, 9'd403, 9'd205, 9'd369};
          return idx[ew];
        end
        346: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd333, 9'd434, 9'd206, 9'd370};
          return idx[ew];
        end
        347: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd365, 9'd435, 9'd207, 9'd371};
          return idx[ew];
        end
        348: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd397, 9'd466, 9'd236, 9'd372};
          return idx[ew];
        end
        349: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd429, 9'd467, 9'd237, 9'd373};
          return idx[ew];
        end
        350: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd461, 9'd498, 9'd238, 9'd374};
          return idx[ew];
        end
        351: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd493, 9'd499, 9'd239, 9'd375};
          return idx[ew];
        end
        352: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd21, 9'd26, 9'd268, 9'd400};
          return idx[ew];
        end
        353: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd53, 9'd27, 9'd269, 9'd401};
          return idx[ew];
        end
        354: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd85, 9'd58, 9'd270, 9'd402};
          return idx[ew];
        end
        355: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd117, 9'd59, 9'd271, 9'd403};
          return idx[ew];
        end
        356: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd149, 9'd90, 9'd300, 9'd404};
          return idx[ew];
        end
        357: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd181, 9'd91, 9'd301, 9'd405};
          return idx[ew];
        end
        358: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd213, 9'd122, 9'd302, 9'd406};
          return idx[ew];
        end
        359: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd245, 9'd123, 9'd303, 9'd407};
          return idx[ew];
        end
        360: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd277, 9'd154, 9'd332, 9'd432};
          return idx[ew];
        end
        361: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd309, 9'd155, 9'd333, 9'd433};
          return idx[ew];
        end
        362: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd341, 9'd186, 9'd334, 9'd434};
          return idx[ew];
        end
        363: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd373, 9'd187, 9'd335, 9'd435};
          return idx[ew];
        end
        364: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd405, 9'd218, 9'd364, 9'd436};
          return idx[ew];
        end
        365: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd437, 9'd219, 9'd365, 9'd437};
          return idx[ew];
        end
        366: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd469, 9'd250, 9'd366, 9'd438};
          return idx[ew];
        end
        367: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd501, 9'd251, 9'd367, 9'd439};
          return idx[ew];
        end
        368: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd29, 9'd282, 9'd396, 9'd464};
          return idx[ew];
        end
        369: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd61, 9'd283, 9'd397, 9'd465};
          return idx[ew];
        end
        370: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd93, 9'd314, 9'd398, 9'd466};
          return idx[ew];
        end
        371: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd125, 9'd315, 9'd399, 9'd467};
          return idx[ew];
        end
        372: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd157, 9'd346, 9'd428, 9'd468};
          return idx[ew];
        end
        373: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd189, 9'd347, 9'd429, 9'd469};
          return idx[ew];
        end
        374: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd221, 9'd378, 9'd430, 9'd470};
          return idx[ew];
        end
        375: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd253, 9'd379, 9'd431, 9'd471};
          return idx[ew];
        end
        376: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd285, 9'd410, 9'd460, 9'd496};
          return idx[ew];
        end
        377: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd317, 9'd411, 9'd461, 9'd497};
          return idx[ew];
        end
        378: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd349, 9'd442, 9'd462, 9'd498};
          return idx[ew];
        end
        379: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd381, 9'd443, 9'd463, 9'd499};
          return idx[ew];
        end
        380: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd413, 9'd474, 9'd492, 9'd500};
          return idx[ew];
        end
        381: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd445, 9'd475, 9'd493, 9'd501};
          return idx[ew];
        end
        382: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd477, 9'd506, 9'd494, 9'd502};
          return idx[ew];
        end
        383: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd509, 9'd507, 9'd495, 9'd503};
          return idx[ew];
        end
        384: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd3, 9'd6, 9'd20, 9'd24};
          return idx[ew];
        end
        385: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd35, 9'd7, 9'd21, 9'd25};
          return idx[ew];
        end
        386: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd67, 9'd38, 9'd22, 9'd26};
          return idx[ew];
        end
        387: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd99, 9'd39, 9'd23, 9'd27};
          return idx[ew];
        end
        388: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd131, 9'd70, 9'd52, 9'd28};
          return idx[ew];
        end
        389: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd163, 9'd71, 9'd53, 9'd29};
          return idx[ew];
        end
        390: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd195, 9'd102, 9'd54, 9'd30};
          return idx[ew];
        end
        391: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd227, 9'd103, 9'd55, 9'd31};
          return idx[ew];
        end
        392: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd259, 9'd134, 9'd84, 9'd56};
          return idx[ew];
        end
        393: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd291, 9'd135, 9'd85, 9'd57};
          return idx[ew];
        end
        394: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd323, 9'd166, 9'd86, 9'd58};
          return idx[ew];
        end
        395: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd355, 9'd167, 9'd87, 9'd59};
          return idx[ew];
        end
        396: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd387, 9'd198, 9'd116, 9'd60};
          return idx[ew];
        end
        397: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd419, 9'd199, 9'd117, 9'd61};
          return idx[ew];
        end
        398: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd451, 9'd230, 9'd118, 9'd62};
          return idx[ew];
        end
        399: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd483, 9'd231, 9'd119, 9'd63};
          return idx[ew];
        end
        400: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd11, 9'd262, 9'd148, 9'd88};
          return idx[ew];
        end
        401: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd43, 9'd263, 9'd149, 9'd89};
          return idx[ew];
        end
        402: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd75, 9'd294, 9'd150, 9'd90};
          return idx[ew];
        end
        403: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd107, 9'd295, 9'd151, 9'd91};
          return idx[ew];
        end
        404: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd139, 9'd326, 9'd180, 9'd92};
          return idx[ew];
        end
        405: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd171, 9'd327, 9'd181, 9'd93};
          return idx[ew];
        end
        406: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd203, 9'd358, 9'd182, 9'd94};
          return idx[ew];
        end
        407: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd235, 9'd359, 9'd183, 9'd95};
          return idx[ew];
        end
        408: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd267, 9'd390, 9'd212, 9'd120};
          return idx[ew];
        end
        409: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd299, 9'd391, 9'd213, 9'd121};
          return idx[ew];
        end
        410: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd331, 9'd422, 9'd214, 9'd122};
          return idx[ew];
        end
        411: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd363, 9'd423, 9'd215, 9'd123};
          return idx[ew];
        end
        412: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd395, 9'd454, 9'd244, 9'd124};
          return idx[ew];
        end
        413: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd427, 9'd455, 9'd245, 9'd125};
          return idx[ew];
        end
        414: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd459, 9'd486, 9'd246, 9'd126};
          return idx[ew];
        end
        415: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd491, 9'd487, 9'd247, 9'd127};
          return idx[ew];
        end
        416: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd19, 9'd14, 9'd276, 9'd152};
          return idx[ew];
        end
        417: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd51, 9'd15, 9'd277, 9'd153};
          return idx[ew];
        end
        418: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd83, 9'd46, 9'd278, 9'd154};
          return idx[ew];
        end
        419: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd115, 9'd47, 9'd279, 9'd155};
          return idx[ew];
        end
        420: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd147, 9'd78, 9'd308, 9'd156};
          return idx[ew];
        end
        421: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd179, 9'd79, 9'd309, 9'd157};
          return idx[ew];
        end
        422: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd211, 9'd110, 9'd310, 9'd158};
          return idx[ew];
        end
        423: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd243, 9'd111, 9'd311, 9'd159};
          return idx[ew];
        end
        424: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd275, 9'd142, 9'd340, 9'd184};
          return idx[ew];
        end
        425: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd307, 9'd143, 9'd341, 9'd185};
          return idx[ew];
        end
        426: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd339, 9'd174, 9'd342, 9'd186};
          return idx[ew];
        end
        427: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd371, 9'd175, 9'd343, 9'd187};
          return idx[ew];
        end
        428: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd403, 9'd206, 9'd372, 9'd188};
          return idx[ew];
        end
        429: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd435, 9'd207, 9'd373, 9'd189};
          return idx[ew];
        end
        430: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd467, 9'd238, 9'd374, 9'd190};
          return idx[ew];
        end
        431: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd499, 9'd239, 9'd375, 9'd191};
          return idx[ew];
        end
        432: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd27, 9'd270, 9'd404, 9'd216};
          return idx[ew];
        end
        433: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd59, 9'd271, 9'd405, 9'd217};
          return idx[ew];
        end
        434: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd91, 9'd302, 9'd406, 9'd218};
          return idx[ew];
        end
        435: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd123, 9'd303, 9'd407, 9'd219};
          return idx[ew];
        end
        436: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd155, 9'd334, 9'd436, 9'd220};
          return idx[ew];
        end
        437: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd187, 9'd335, 9'd437, 9'd221};
          return idx[ew];
        end
        438: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd219, 9'd366, 9'd438, 9'd222};
          return idx[ew];
        end
        439: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd251, 9'd367, 9'd439, 9'd223};
          return idx[ew];
        end
        440: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd283, 9'd398, 9'd468, 9'd248};
          return idx[ew];
        end
        441: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd315, 9'd399, 9'd469, 9'd249};
          return idx[ew];
        end
        442: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd347, 9'd430, 9'd470, 9'd250};
          return idx[ew];
        end
        443: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd379, 9'd431, 9'd471, 9'd251};
          return idx[ew];
        end
        444: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd411, 9'd462, 9'd500, 9'd252};
          return idx[ew];
        end
        445: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd443, 9'd463, 9'd501, 9'd253};
          return idx[ew];
        end
        446: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd475, 9'd494, 9'd502, 9'd254};
          return idx[ew];
        end
        447: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd507, 9'd495, 9'd503, 9'd255};
          return idx[ew];
        end
        448: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd7, 9'd22, 9'd28, 9'd280};
          return idx[ew];
        end
        449: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd39, 9'd23, 9'd29, 9'd281};
          return idx[ew];
        end
        450: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd71, 9'd54, 9'd30, 9'd282};
          return idx[ew];
        end
        451: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd103, 9'd55, 9'd31, 9'd283};
          return idx[ew];
        end
        452: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd135, 9'd86, 9'd60, 9'd284};
          return idx[ew];
        end
        453: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd167, 9'd87, 9'd61, 9'd285};
          return idx[ew];
        end
        454: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd199, 9'd118, 9'd62, 9'd286};
          return idx[ew];
        end
        455: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd231, 9'd119, 9'd63, 9'd287};
          return idx[ew];
        end
        456: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd263, 9'd150, 9'd92, 9'd312};
          return idx[ew];
        end
        457: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd295, 9'd151, 9'd93, 9'd313};
          return idx[ew];
        end
        458: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd327, 9'd182, 9'd94, 9'd314};
          return idx[ew];
        end
        459: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd359, 9'd183, 9'd95, 9'd315};
          return idx[ew];
        end
        460: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd391, 9'd214, 9'd124, 9'd316};
          return idx[ew];
        end
        461: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd423, 9'd215, 9'd125, 9'd317};
          return idx[ew];
        end
        462: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd455, 9'd246, 9'd126, 9'd318};
          return idx[ew];
        end
        463: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd487, 9'd247, 9'd127, 9'd319};
          return idx[ew];
        end
        464: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd15, 9'd278, 9'd156, 9'd344};
          return idx[ew];
        end
        465: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd47, 9'd279, 9'd157, 9'd345};
          return idx[ew];
        end
        466: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd79, 9'd310, 9'd158, 9'd346};
          return idx[ew];
        end
        467: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd111, 9'd311, 9'd159, 9'd347};
          return idx[ew];
        end
        468: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd143, 9'd342, 9'd188, 9'd348};
          return idx[ew];
        end
        469: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd175, 9'd343, 9'd189, 9'd349};
          return idx[ew];
        end
        470: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd207, 9'd374, 9'd190, 9'd350};
          return idx[ew];
        end
        471: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd239, 9'd375, 9'd191, 9'd351};
          return idx[ew];
        end
        472: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd271, 9'd406, 9'd220, 9'd376};
          return idx[ew];
        end
        473: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd303, 9'd407, 9'd221, 9'd377};
          return idx[ew];
        end
        474: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd335, 9'd438, 9'd222, 9'd378};
          return idx[ew];
        end
        475: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd367, 9'd439, 9'd223, 9'd379};
          return idx[ew];
        end
        476: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd399, 9'd470, 9'd252, 9'd380};
          return idx[ew];
        end
        477: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd431, 9'd471, 9'd253, 9'd381};
          return idx[ew];
        end
        478: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd463, 9'd502, 9'd254, 9'd382};
          return idx[ew];
        end
        479: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd495, 9'd503, 9'd255, 9'd383};
          return idx[ew];
        end
        480: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd23, 9'd30, 9'd284, 9'd408};
          return idx[ew];
        end
        481: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd55, 9'd31, 9'd285, 9'd409};
          return idx[ew];
        end
        482: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd87, 9'd62, 9'd286, 9'd410};
          return idx[ew];
        end
        483: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd119, 9'd63, 9'd287, 9'd411};
          return idx[ew];
        end
        484: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd151, 9'd94, 9'd316, 9'd412};
          return idx[ew];
        end
        485: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd183, 9'd95, 9'd317, 9'd413};
          return idx[ew];
        end
        486: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd215, 9'd126, 9'd318, 9'd414};
          return idx[ew];
        end
        487: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd247, 9'd127, 9'd319, 9'd415};
          return idx[ew];
        end
        488: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd279, 9'd158, 9'd348, 9'd440};
          return idx[ew];
        end
        489: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd311, 9'd159, 9'd349, 9'd441};
          return idx[ew];
        end
        490: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd343, 9'd190, 9'd350, 9'd442};
          return idx[ew];
        end
        491: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd375, 9'd191, 9'd351, 9'd443};
          return idx[ew];
        end
        492: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd407, 9'd222, 9'd380, 9'd444};
          return idx[ew];
        end
        493: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd439, 9'd223, 9'd381, 9'd445};
          return idx[ew];
        end
        494: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd471, 9'd254, 9'd382, 9'd446};
          return idx[ew];
        end
        495: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd503, 9'd255, 9'd383, 9'd447};
          return idx[ew];
        end
        496: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd31, 9'd286, 9'd412, 9'd472};
          return idx[ew];
        end
        497: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd63, 9'd287, 9'd413, 9'd473};
          return idx[ew];
        end
        498: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd95, 9'd318, 9'd414, 9'd474};
          return idx[ew];
        end
        499: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd127, 9'd319, 9'd415, 9'd475};
          return idx[ew];
        end
        500: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd159, 9'd350, 9'd444, 9'd476};
          return idx[ew];
        end
        501: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd191, 9'd351, 9'd445, 9'd477};
          return idx[ew];
        end
        502: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd223, 9'd382, 9'd446, 9'd478};
          return idx[ew];
        end
        503: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd255, 9'd383, 9'd447, 9'd479};
          return idx[ew];
        end
        504: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd287, 9'd414, 9'd476, 9'd504};
          return idx[ew];
        end
        505: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd319, 9'd415, 9'd477, 9'd505};
          return idx[ew];
        end
        506: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd351, 9'd446, 9'd478, 9'd506};
          return idx[ew];
        end
        507: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd383, 9'd447, 9'd479, 9'd507};
          return idx[ew];
        end
        508: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd415, 9'd478, 9'd508, 9'd508};
          return idx[ew];
        end
        509: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd447, 9'd479, 9'd509, 9'd509};
          return idx[ew];
        end
        510: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd479, 9'd510, 9'd510, 9'd510};
          return idx[ew];
        end
        511: begin
          automatic logic [9-1:0] idx [0:3] = '{9'd511, 9'd511, 9'd511, 9'd511};
          return idx[ew];
        end
        default: return 0;
	  endcase
	endcase
  endfunction: query_shf_idx

  // Input shuffle index, output sequential index  
  // Used in Shuffle Unit to convert shuffle index to sequential index
  function automatic logic [${clog2(riva_pkg::DLEN*riva_pkg::MaxNrLanes/4)}-1:0] query_seq_idx(int NrLanes, int shfNbIdx, rvv_pkg::vew_e ew);
    unique case (NrLanes)
      1: begin
        automatic logic [5-1:0] idx [0:3];
        for (int seqIdx = 0; seqIdx < 32; seqIdx++)
          idx[query_shf_idx(NrLanes, seqIdx, ew)] = seqIdx;
        return idx[shfNbIdx];
      end
      2: begin
        automatic logic [6-1:0] idx [0:3];
        for (int seqIdx = 0; seqIdx < 64; seqIdx++)
          idx[query_shf_idx(NrLanes, seqIdx, ew)] = seqIdx;
        return idx[shfNbIdx];
      end
      4: begin
        automatic logic [7-1:0] idx [0:3];
        for (int seqIdx = 0; seqIdx < 128; seqIdx++)
          idx[query_shf_idx(NrLanes, seqIdx, ew)] = seqIdx;
        return idx[shfNbIdx];
      end
      8: begin
        automatic logic [8-1:0] idx [0:3];
        for (int seqIdx = 0; seqIdx < 256; seqIdx++)
          idx[query_shf_idx(NrLanes, seqIdx, ew)] = seqIdx;
        return idx[shfNbIdx];
      end
      16: begin
        automatic logic [9-1:0] idx [0:3];
        for (int seqIdx = 0; seqIdx < 512; seqIdx++)
          idx[query_shf_idx(NrLanes, seqIdx, ew)] = seqIdx;
        return idx[shfNbIdx];
      end
      default: return 0;
    endcase
  endfunction: query_seq_idx

endpackage