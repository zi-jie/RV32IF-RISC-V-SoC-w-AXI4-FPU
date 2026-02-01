#include "stdlib.h"
int main(){
    extern unsigned const int div1;
    extern unsigned const int div2;
    extern unsigned int _test_start;

    unsigned int a = div1;
    unsigned int b = div2;

    while(a!=0 && b !=0){
        if(a >= b){
            a = a % b;
        }
        else{
            b = b % a;
        }
    }

    if(a >= b){
        _test_start = a;
    }
    else {
        _test_start = b;
    }

    return 0;
}