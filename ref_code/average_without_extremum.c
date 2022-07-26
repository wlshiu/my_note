#define INT_MAX 2147483647
#define INT_MIN -2147483648

/**
 *  @brief  Average salary[x] without maximum and minimum
 *              the elements of salary[] are NOT the same.
 *              https://iter01.com/548635.html
 *
 *  @param [in] salary
 *  @param [in] salarySize
 *  @return
 *      average value
 */
float average(int *salary, int salarySize)
{
    int sum = 0, max = INT_MIN, min = INT_MAX;

    for (int i = 0; i < salarySize; ++i)
    {
        sum += salary[i];

        if( min > salary[i] )
            min = salary[i];
        else if( max < salary[i] )
            max = salary[i];
    }
    return (float)(sum - min - max) / (salarySize - 2);
}