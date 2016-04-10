There's a first time for everything, and it was my turn to get bit by a buffer overflow.

My ISS Notification Lamp operates as a state machine. The program successfully completed the states for acquiring the current Latitude and Longitude. It then made it through the state for requesting the current time at that Lat/Long. However, the machine never advanced to the next state, instead falling into a timeout case I built.

My first hunch was that I was not receiving good data, or that my request was malformed. Running Wireshark to examine the contents of my requests showed this was not the issue. To troubleshoot the state machine, I inserted statements that printed the current state to the serial terminal. I was able to see instantly that my state was being corrupted, because after the section of code below, my state printed as 12426, while the enum that stored my state only went from 0-4.

{% highlight c %}
#define BUFF_SIZE 50
char url_var_part[BUFF_SIZE];
{% endhighlight %}

{% highlight c %}
case STATE_GET_DATA_TIME:
          //request format http://api.timezonedb.com/?format=json&lat=<LAT>&lng=<LONG>&key=<Your_API_Key>
          timer = millis();
          Serial.println("\n>>> REQ TIME");
          fill_ip_with_dns(website_name_time, website_ip_time);
          url_buffer[0]='\0';
          strcat(url_buffer,"&lat=");
          strcat(url_buffer,current_geoiplat_string);
          strcat(url_buffer,"&lng=");
          strcat(url_buffer,current_geoiplong_string);
          strcat(url_buffer,"&key=");
          strcat(url_buffer,apikey);
          ether.urlEncode(url_buffer,url_var_part);
          ether.browseUrl(PSTR("/?format=json"), url_var_part, website_name_time, my_result_cb);
          state_cb = STATE_CB_WAIT;
          state = STATE_PROCESS_DATA;
          break;
{% endhighlight %}

When using the function ether.urlEncode, the resulting string clocked in at 58 characters, which is clearly larger than the 50 characters I allocated to url_var_part.

This was the first buffer overflow I have found in my own code, and the frustration it caused me has inspired a new concern for the strings I use in my program. Though they were not at fault in this case, I changed all of my strcat functions to strlcat, which is a safer way to concatenate strings.