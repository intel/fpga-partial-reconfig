set -e
quartus_sh --flow compile blinking_led -c blinking_led
quartus_sh --flow compile blinking_led -c blinking_led_slow
quartus_sh --flow compile blinking_led -c blinking_led_empty
quartus_sh --flow compile blinking_led -c blinking_led_default
