//// ============================================
//// Testbench FIFO
//// ============================================
//`timescale 1ns/1ps
//
//module tb_FIFO;
//
//parameter W = 8;
//parameter L = 32;   // FIFO mới 32 byte
//
//reg clk;
//reg reset;
//reg wr_en;
//reg rd_en;
//reg [W-1:0] wr_data;
//
//wire [W-1:0] rd_data;
//wire empty;
//wire full;
//
//// Debug
////wire [5:0] wr_ptr_test;
////wire [5:0] rd_ptr_test;
////wire [6:0] count_test;
//
//
//FIFO #(.W(W), .L(L)) FIFO_uut (
//    .clk(clk),
//    .reset(reset),
//    .wr_en(wr_en),
//    .rd_en(rd_en),
//    .wr_data(wr_data),
//    .rd_data(rd_data),
//    .empty(empty),
//    .full(full)
//	 
//	 // Debug
////	 ,
////	 .wr_ptr_test (wr_ptr_test),
////	 .rd_ptr_test (rd_ptr_test),
////	 .count_test (count_test)
//);
//
//// =============================
//// Clock
//// =============================
//initial begin
//    clk = 0;
//    forever #10 clk = ~clk;
//end
//
//// =============================
//// Test sequence
//// =============================
//initial begin
//    reset   = 1;
//    wr_en   = 0;
//    rd_en   = 0;
//    wr_data = 0;
//
//    #40;
//    reset = 0;
//
//    // =====================================
//    // 1. Fill FIFO (test FULL)
//    // =====================================
//    $display("=== WRITE FULL ===");
//    repeat(L) begin
//        @(posedge clk);
//        wr_en   = 1;
//        wr_data = wr_data + 1;
//        @(posedge clk);
//        wr_en = 0;
//    end
//
//    // thử ghi khi FULL
//    @(posedge clk);
//    wr_en = 1;
//    wr_data = 8'hFF;
//    @(posedge clk);
//    wr_en = 0;
//
//    // =====================================
//    // 2. Read FIFO (test EMPTY)
//    // =====================================
//    $display("=== READ EMPTY ===");
//    repeat(L) begin
//        @(posedge clk);
//        rd_en = 1;
//        @(posedge clk);
//        rd_en = 0;
//    end
//
//    // thử đọc khi EMPTY
//    @(posedge clk);
//    rd_en = 1;
//    @(posedge clk);
//    rd_en = 0;
//
//    // =====================================
//    // 3. Write + Read đồng thời
//    // =====================================
//    $display("=== SIMULTANEOUS WR/RD ===");
//    repeat(10) begin
//        @(posedge clk);
//        wr_en   = 1;
//        rd_en   = 1;
//        wr_data = wr_data + 2;
//        @(posedge clk);
//        wr_en = 0;
//        rd_en = 0;
//    end
//
//    // =====================================
//    // 4. Fill lại FIFO
//    // =====================================
//    $display("=== WRITE AGAIN ===");
//    repeat(L/2) begin
//        @(posedge clk);
//        wr_en   = 1;
//        wr_data = wr_data + 3;
//        @(posedge clk);
//        wr_en = 0;
//    end
//
//    // =====================================
//    // 5. Read lại FIFO
//    // =====================================
//    $display("=== FINAL READ ===");
//    repeat(L/2) begin
//        @(posedge clk);
//        rd_en = 1;
//        @(posedge clk);
//        rd_en = 0;
//    end
//
//    #100;
//    $stop;
//end
//
//endmodule


//`timescale 1ns/1ps
//
//module tb_FIFO;
//
//    parameter W = 8;
//    parameter L = 8;   // dùng nhỏ để dễ test full/empty nhanh
//
//    reg clk;
//    reg reset;
//    reg wr_en;
//    reg rd_en;
//    reg [W-1:0] wr_data;
//
//    wire [W-1:0] rd_data;
//    wire full;
//    wire empty;
//
//    // ================= DUT =================
//    FIFO #(W, L) dut (
//        .clk(clk),
//        .reset(reset),
//        .wr_en(wr_en),
//        .rd_en(rd_en),
//        .wr_data(wr_data),
//        .rd_data(rd_data),
//        .empty(empty),
//        .full(full)
//    );
//
//    // ================= CLOCK =================
//    always #5 clk = ~clk;   // 100MHz
//
//    // ================= TASK =================
//    task write_fifo(input [W-1:0] data);
//    begin
//        @(posedge clk);
//        wr_en = 1;
//        rd_en = 0;
//        wr_data = data;
//
//        @(posedge clk);
//        wr_en = 0;
//    end
//    endtask
//
//    task read_fifo;
//    begin
//        @(posedge clk);
//        wr_en = 0;
//        rd_en = 1;
//
//        @(posedge clk);
//        rd_en = 0;
//    end
//    endtask
//
//    // ================= MONITOR =================
//    initial begin
//        $display("Time\twr_en\trd_en\twr_data\trd_data\tfull\tempty");
//        $monitor("%0t\t%b\t%b\t%h\t%h\t%b\t%b",
//                 $time, wr_en, rd_en, wr_data, rd_data, full, empty);
//    end
//
//    // ================= TEST =================
//    initial begin
//        clk = 0;
//        reset = 1;
//        wr_en = 0;
//        rd_en = 0;
//        wr_data = 0;
//
//        // Reset
//        #20;
//        reset = 0;
//
//        // ================= TEST 1: WRITE =================
//        $display("\n=== WRITE FIFO ===");
//        repeat (L) begin
//            write_fifo($random);
//        end
//
//        // Thử ghi thêm khi full
//        $display("\n=== WRITE WHEN FULL (SHOULD IGNORE) ===");
//        write_fifo(8'hAA);
//
//        // ================= TEST 2: READ =================
//        $display("\n=== READ FIFO ===");
//        repeat (L) begin
//            read_fifo();
//        end
//
//        // Thử đọc khi empty
//        $display("\n=== READ WHEN EMPTY (SHOULD IGNORE) ===");
//        read_fifo();
//
//        // ================= TEST 3: WRITE + READ =================
//        $display("\n=== SIMULTANEOUS READ & WRITE ===");
//
//        repeat (5) begin
//            @(posedge clk);
//            wr_en = 1;
//            rd_en = 1;
//            wr_data = $random;
//        end
//
//        @(posedge clk);
//        wr_en = 0;
//        rd_en = 0;
//
//        // ================= FINISH =================
//        #50;
//        $stop;
//    end
//
//endmodule


//`timescale 1ns/1ps
//
//module tb_FIFO;
//	
//	parameter W = 8;
//	parameter L = 32;
//	
//	reg clk;
//	reg reset;
//	reg write_en;
//	reg read_en;
//	reg [W - 1:0] data_in;
//	
//	wire full;
//	wire empty;
//	wire [W - 1:0] data_out;
//	
//	FIFO #(
//		.W (W),
//		.L (L)
//	) fifo_test (
//		.clk	(clk),
//		.reset	(reset),
//		.write_en (write_en),
//		.read_en	(read_en),
//		.data_in (data_in),
//		.full	(full),
//		.empty (empty),
//		.data_out (data_out)
//	);
//	
//	initial begin
//		clk = 0;
//		forever #10 clk = ~clk;
//	end
//	
//	initial begin
//		reset = 0;
//		write_en = 0;
//		read_en = 0;
//		data_in = 8'b0;
//		
//		#20 reset = 1;
//		
//		#20 reset = 0;
//		write;
//		
//		#20 read;
//		
//		
//		#400 $finish;
//		
//		
//		
//	end
//	
//	task write;
//			begin
//				write_en = 1;
//				read_en = 0;
//				data_in = $random;
//			end
//		endtask
//		
//		task read;
//			begin
//				write_en = 0;
//				read_en = 1;
//			end
//		endtask
//	
//endmodule

`timescale 1ns/1ps

module tb_FIFO;
    
    parameter W = 8;
    parameter L = 32;
    
    reg clk;
    reg reset;
    reg write_en;
    reg read_en;
    reg [W - 1:0] data_in;
    
    wire full;
    wire empty;
    wire [W - 1:0] data_out;
    
    integer i;
    
    FIFO #(
        .W (W),
        .L (L)
    ) fifo_test (
        .clk       (clk),
        .reset     (reset),
        .write_en  (write_en),
        .read_en   (read_en),
        .data_in   (data_in),
        .full      (full),
        .empty     (empty),
        .data_out  (data_out)
    );
    
    // CLOCK
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // ================= TASK =================
    task write;
    begin
        @(posedge clk);
        write_en = 1;
        read_en  = 0;
        data_in  = $random;

        @(posedge clk);
        write_en = 0;
    end
    endtask
        
    task read;
    begin
        @(posedge clk);
        write_en = 0;
        read_en  = 1;

        @(posedge clk);
        read_en = 0;
    end
    endtask

    // ================= TEST =================
    initial begin
        reset = 1;
        write_en = 0;
        read_en = 0;
        data_in = 0;
        
        #40;
        reset = 0;

        // ================= WRITE FULL =================
        $display("=== WRITE FULL ===");
        repeat (L) begin
            write;
        end

        // thử ghi thêm khi full (phải bị ignore)
        $display("=== WRITE WHEN FULL ===");
        write;

        // ================= READ ALL =================
        #20;
        $display("=== READ ALL ===");
        repeat (L) begin
            read;
        end

        // thử đọc khi empty (phải giữ nguyên data_out)
        $display("=== READ WHEN EMPTY ===");
        read;

        #200;
        $finish;
    end

endmodule




















