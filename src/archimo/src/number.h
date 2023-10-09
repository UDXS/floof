namespace am_wasabi {

template <int W, int F>
class q {
    
};

struct number{
    enum class format {
        uint,
        sint,
        q16_16,
        q6_6,
        q12_0,
        q2_10
    };

    format type;

    union store {
        uint32_t uint;
        int32_t sint;
        q<16,16>  q16_16;
        q<6,6> q6_6;
        q<12,0> q12_0;
        q<2,10> q2_10;
    };

    store data;
};

}