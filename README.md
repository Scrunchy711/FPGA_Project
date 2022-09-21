# FPGA_Project

This FPGA project was part of the final submission of SUTD's Digital System Lab Course

# Light Show Display

We used the 7 digit segments to create a light show display that selects which figure 8 is not active on the board which creates different patterns when the segment lights up from segment to segment. Switch[0] is used for toggling the speed of the segment scroller between 10 Hz and 2Hz. Next, switch[7] is used to play or stop the entire sequence. Lastly, switch[6] is used to catch the pattern, letting it run only within a single 7 segment digit.

At least 4 functions are running concurrently. We needed to define 7 cases for storing the digit patterns (selecting which of the 4 segments need to be lighted up), so we defined a 3 bit variable to store. Concurrently, there is a 7 case, 3 bit segment selector that is running( the initial case was repeated twice, one at start and one at end), which selects the part of the segment to be controlled, and also the state of the LED to be on or off (1bit, 2 cases). Like in a computer, all these functions had to be synced perfectly to get the 7 segment light show display.

At the same time, a 2-1 multiplexor was used for toggling the speed at which the cases should be transiting at, from one case to the next, and each case is incremented by 1 on the rising edge of the clock. This clock is fed back into the sensitivity list for all other functions.

# Digital Clock with Knight Rider Alarm

We followed current implementations of real-life digital clocks. Using the seven segment display, we have the case of {switch[0], switch[1]} that allows the toggling between 2 arrangements of time: hh:mm ({0.0}) and mm:ss ({0,1}). 

Using ({switch[0], switch[1]}), we also have the case of ({1,0}) to allow the setting of the clock to follow the current time. The push buttons have been debounced, with the btn_right allowing horizontal scroll between the tenth hour digits, the ones hour digits, the tenth minute digits and the ones minute digits. The flashing of the seven-segment display also indicates to the user the current position of digits in which he is adjusting. Note also that logic has been implemented that allows users to set time only between 0000 to 2359. The btn_up allows for vertical scrolling, 0->2 for tens hour digits, 0->3 for ones hour digits, 0->5 for tens minute digits and 0->9 for ones minute digits. Pressing the btn_enter confirms the input and returning to case ({0,0}) and ({0,1}) shows the real time being set and in increment accordingly. 

For the case of ({1,1}), allows the setting of the alarm time. Again, it uses the same process as seen in the case for ({1,0}), just without the enter button. Once the real time clock as shown in case ({0,0}) is the same as the alarm time set, a knight rider display using 2 leds to flow horizontally to and fro is shown as the alarm indicator, lasting for 10 seconds before turning off. 

<a href="https://youtu.be/aF9W5K1BQpI" target="_blank"><img src="https://i.ytimg.com/vi/aF9W5K1BQpI/hqdefault.jpg?sqp=-oaymwEbCKgBEF5IVfKriqkDDggBFQAAiEIYAXABwAEG\u0026rs=AOn4CLAaYTBxE9j4vk9KxJDv8dNstsSFqw" 
alt="IMAGE ALT TEXT HERE" width="240" height="180" border="10" /></a>

