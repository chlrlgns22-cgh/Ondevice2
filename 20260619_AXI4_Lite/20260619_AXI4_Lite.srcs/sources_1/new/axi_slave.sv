`timescale 1ns / 1ps

module axi_slave (
    input  logic        ACLK,
    input  logic        ARESETn,
    // AW channel
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // W channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // B channel
    output logic [ 1:0] BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    // AR channel
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // R channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP
);

    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    logic [31:0] addr_r;
    /*********************** Write Transaction ************************/
    // AW Channel
    typedef enum logic {
        AW_IDLE  = 0,
        AW_READY
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state <= AW_IDLE;
        end else begin
            aw_state <= aw_state_next;
        end
    end

    always_comb begin
        aw_state_next = aw_state;
        AWREADY = 1'b0;
        addr_r = AWADDR;
        case (aw_state)
            AW_IDLE: begin
                AWREADY = 1'b0;
                if (AWVALID) begin
                    aw_state_next = AW_READY;
                end
            end
            AW_READY: begin
                addr_r = AWADDR;
                AWREADY = 1'b1;
                aw_state_next = AW_IDLE;
            end
            default: begin
                aw_state_next = AW_IDLE;
                AWREADY = 1'b0;
                addr_r = AWADDR;
            end
        endcase
    end

    // W Channel
    typedef enum logic {
        W_IDLE  = 0,
        W_READY
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state <= W_IDLE;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state;
        WREADY = 1'b0;
        case (w_state)
            W_IDLE: begin
                WREADY = 1'b0;
                if (WVALID & AWVALID & AWREADY) begin
                    w_state_next = W_READY;
                end
            end
            W_READY: begin
                w_state_next = W_IDLE;
                WREADY = 1'b1;
                case (addr_r[3:2])
                    2'd0: slv_reg0 = WDATA;
                    2'd1: slv_reg1 = WDATA;
                    2'd2: slv_reg2 = WDATA;
                    2'd3: slv_reg3 = WDATA;
                endcase
            end
            default: begin
                w_state_next = W_IDLE;
                WREADY = 1'b0;
            end
        endcase
    end

    // B Channel
    typedef enum logic {
        B_IDLE  = 0,
        B_VALID
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state;
        BVALID = 1'b0;
        BRESP = 2'b00;
        case (b_state)
            B_IDLE: begin
                BVALID = 1'b0;
                if (WVALID & WREADY) begin
                    b_state_next = B_VALID;
                end
            end
            B_VALID: begin
                BVALID = 1'b1;
                BRESP  = 2'b00;  // ok
                if (BREADY) begin
                    b_state_next = B_IDLE;
                end
            end
            default: begin
                BVALID = 1'b0;
                BRESP = 2'b00;
                b_state_next = B_IDLE;
            end
        endcase
    end

    /*********************** Read Transaction ************************/
    logic [31:0] araddr;
    // AR Channel
    typedef enum logic {
        AR_IDLE  = 0,
        AR_READY
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state <= AR_IDLE;
        end else begin
            ar_state <= ar_state_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ARREADY = 1'b0;
        araddr = ARADDR;
        case (ar_state)
            AR_IDLE: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next = AR_READY;
                end
            end
            AR_READY: begin
                araddr = ARADDR;
                ARREADY = 1'b1;
                ar_state_next = AR_IDLE;
            end
            default: begin
                ar_state_next = AR_IDLE;
                ARREADY = 1'b0;
                araddr = ARADDR;
            end
        endcase
    end

    // R Channel
    typedef enum logic {
        R_IDLE  = 0,
        R_VALID
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        RDATA = 0;
        RVALID = 1'b0;
        RRESP = 2'b00;  // OK
        case (r_state)
            R_IDLE: begin
                RVALID = 1'b0;
                if (ARVALID & ARREADY) begin
                    r_state_next = R_VALID;
                end
            end
            R_VALID: begin
                RVALID = 1'b1;
                RRESP  = 2'b00;  // OK
                case (araddr[3:2])
                    2'd0: RDATA = slv_reg0;
                    2'd1: RDATA = slv_reg1;
                    2'd2: RDATA = slv_reg2;
                    2'd3: RDATA = slv_reg3;
                endcase
                if (RVALID & RREADY) begin
                    r_state_next = R_IDLE;
                end
            end
            default: begin
                RVALID = 1'b0;
                r_state_next = R_IDLE;
            end
        endcase
    end
endmodule
