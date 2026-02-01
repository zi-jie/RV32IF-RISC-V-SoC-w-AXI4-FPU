#include"stdlib.h"
int main(){
    extern const int  array_size;
    extern const int  array_addr;
    extern int _test_start;

    int sort_array[array_size];
    int tmp;
    
    for(int i = 0; i < array_size; i++){
        sort_array[i] = *(&array_addr + i); 
    }
    for(int i = 0; i < array_size -1; i++){
        for(int j = 0; j < array_size -1 -i; j++){
            if(sort_array[j] > sort_array[j+1]){
                tmp = sort_array[j];
                sort_array[j] = sort_array[j+1];
                sort_array[j+1] = tmp;
            }
        }
    }
    for( int i = 0; i < array_size; i++){
        *(&_test_start + i) = sort_array[i];
    }
    return 0; 
}