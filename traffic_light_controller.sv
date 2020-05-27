// shell for advanced traffic light controller (stretch goal)
// CSE140L   Summer II  2019
// semi-independent operation of east and west straight and left signals
//  see assignment writeup

module traffic_light_controller(
  input clk,
        reset,
        ew_left_sensor,
        ew_str_sensor,		
        ns_sensor,
  output logic[1:0] ew_left_light,     
  		            ew_str_light,	   	
			        ns_light);

  //define color lights here
  parameter RED = 2'b00,
            YELLOW = 2'b01,
				GREEN = 2'b10;
  //define priority ranks here
  parameter FIRST = 2'b10,
            SECOND = 2'b01,
				THIRD = 2'b00;
  //define states here
  enum logic [2:0] {IDLE=3'b000, EWG=3'b001, EWY=3'b010, EWLG=3'b011, EWLY=3'b100, NSG=3'b101, NSY=3'b110} state;
  
  logic[3:0] traffic_cycle;
  logic[2:0] empty_cycle;
  logic[1:0] ews_rank;
  logic[1:0] ewl_rank;
  logic[1:0] ns_rank;
  logic is_empty;
  logic is_ten_seconds;
  
					  
  always_ff @(posedge clk)
    begin
      if (reset) begin
		  state <= IDLE;
		  empty_cycle <= 0;
		  traffic_cycle <= 0;
		  is_empty <= 0;
		  is_ten_seconds <= 0;
		  ews_rank <= FIRST;
        ewl_rank <= SECOND;
        ns_rank <= THIRD;
		  ew_left_light <= RED;
		  ew_str_light <= RED;
		  ns_light <= RED;
      end else
        case (state)
          IDLE: begin
				//all red state
			   ew_left_light <= RED;
				ew_str_light <= RED;
				ns_light <= RED;
				//traffic priority logic goes here
				if( ews_rank == FIRST ) begin
				  if( ew_str_sensor ) state <= EWG; 
				  else if( ewl_rank == SECOND ) begin
				    if( ew_left_sensor ) state <= EWLG;
					 else if( ns_sensor ) state <= NSG;
				  end 
				  else if( ns_rank == SECOND ) begin
				    if( ns_sensor ) state <= NSG;
					 else if( ew_left_sensor ) state <= EWLG;
				  end
				end
				
				if( ewl_rank == FIRST ) begin
				  if( ew_left_sensor ) state <= EWLG; 
				  else if( ews_rank == SECOND ) begin
				    if( ew_str_sensor ) state <= EWG;
					 else if( ns_sensor ) state <= NSG;
				  end 
				  else if( ns_rank == SECOND ) begin
				    if( ns_sensor ) state <= NSG;
					 else if( ew_str_sensor ) state <= EWG;
				  end
				end
				
				if( ns_rank == FIRST ) begin
				  if( ns_sensor ) state <= NSG; 
				  else if( ewl_rank == SECOND ) begin
				    if( ew_left_sensor ) state <= EWLG;
					 else if( ew_str_sensor ) state <= EWG;
				  end 
				  else if( ews_rank == SECOND ) begin
				    if( ew_str_sensor ) state <= EWG;
					 else if( ew_left_sensor ) state <= EWLG;
				  end
				end
				
				//If there is no trafic reset the priority to defaults
				if( !ew_left_sensor && !ew_str_sensor && !ns_sensor ) begin
			 	  ews_rank <= FIRST;
              ewl_rank <= SECOND;
              ns_rank <= THIRD;
				end

			 end
			 EWG: begin
				//set the light colors
			   ew_left_light <= RED;
				ew_str_light <= GREEN;
				ns_light <= RED;
				//5 cycle rule for no traffic
				if( !ew_str_sensor ) is_empty = 1'b1;
				if( is_empty ) empty_cycle <= empty_cycle + 3'b001;
				if( empty_cycle == 3'b100 ) begin
				  is_empty <= 0;
				  empty_cycle <= 0;
				  state <= EWY;
				end
				//10 cycle rule for other traffic 
				traffic_cycle <= traffic_cycle + 4'b0001;
				if( traffic_cycle == 4'b1001 ) is_ten_seconds = 1'b1;
				if( is_ten_seconds && (ew_left_sensor || ns_sensor) ) begin
				  traffic_cycle <= 0;
				  is_ten_seconds <= 0;
				  state <= EWY;
				end
			 end
			 EWY: begin
				//set the light colors
			   ew_left_light <= RED;
				ew_str_light <= YELLOW;
				ns_light <= RED;
				//2 cycles for a yellow light
				empty_cycle <= empty_cycle + 3'b001;
				if( empty_cycle == 3'b001 ) begin
				  //update the priority ranks
				  ews_rank <= THIRD;
              ewl_rank <= ewl_rank + 2'b01;
              ns_rank <= ns_rank + 2'b01;
				  empty_cycle <= 0;
				  state <= IDLE;
				end
			 end
			 EWLG: begin
				//set the light colors
			   ew_left_light <= GREEN;
				ew_str_light <= RED;
				ns_light <= RED;
				//5 cycle rule for no traffic
				if( !ew_left_sensor ) is_empty = 1'b1;
				if( is_empty ) empty_cycle <= empty_cycle + 3'b001;
				if( empty_cycle == 3'b100 ) begin
				  is_empty <= 0;
				  empty_cycle <= 0;
				  state <= EWLY;
				end
				//10 cycle rule for other traffic 
				traffic_cycle <= traffic_cycle + 4'b0001;
				if( traffic_cycle == 4'b1001 ) is_ten_seconds = 1'b1;
				if( is_ten_seconds && (ew_str_sensor || ns_sensor) ) begin
				  traffic_cycle <= 0;
				  is_ten_seconds <= 0;
				  state <= EWLY;
				end
			 end
			 EWLY: begin
				//set the light colors
			   ew_left_light <= YELLOW;
				ew_str_light <= RED;
				ns_light <= RED;
				//2 cycles for a yellow light
				empty_cycle <= empty_cycle + 3'b001;
				if( empty_cycle == 3'b001 ) begin
				  //update the priority ranks
				  ewl_rank <= THIRD;
				  ews_rank <= ews_rank + 2'b01;
              ns_rank <= ns_rank + 2'b01;
				  empty_cycle <= 0;
				  state <= IDLE;
				end
			 end
			 NSG: begin
				//set the light colors
			   ew_left_light <= RED;
				ew_str_light <= RED;
				ns_light <= GREEN;
				//5 cycle rule for no traffic
				if( !ns_sensor ) is_empty = 1'b1;
				if( is_empty ) empty_cycle <= empty_cycle + 3'b001;
				if( empty_cycle == 3'b100 ) begin
				  is_empty <= 0;
				  empty_cycle <= 0;
				  state <= NSY;
				end
				//10 cycle rule for other traffic 
				traffic_cycle <= traffic_cycle + 4'b0001;
				if( traffic_cycle == 4'b1001 ) is_ten_seconds = 1'b1;
				if( is_ten_seconds && (ew_str_sensor || ew_left_sensor) ) begin
				  traffic_cycle <= 0;
				  is_ten_seconds <= 0;
				  state <= NSY;
				end
			 end
			 NSY: begin
				//set the light colors
			   ew_left_light <= RED;
				ew_str_light <= RED;
				ns_light <= YELLOW;
				//2 cycles for a yellow light
				empty_cycle <= empty_cycle + 3'b001;
				if( empty_cycle == 3'b001 ) begin
				  //update the priority ranks
				  ns_rank <= THIRD;
				  ews_rank <= ews_rank + 2'b01;
              ewl_rank <= ewl_rank + 2'b01;
				  empty_cycle <= 0;
				  state <= IDLE;
				end
			 end
			
		  endcase
    
	 end

endmodule 