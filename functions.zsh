cmdfu(){ curl "http://www.commandlinefu.com/commands/matching/$@/$(echo -n $@ | openssl base64)/plaintext"; }
man2pdf(){ man -t $1 | open -f -a preview; }
biggest(){ du -sk ./* | sort -n | awk 'BEGIN{ pref[1]="K"; pref[2]="M"; pref[3]="G";} { total = total + $1; x = $1; y = 1; while( x > 1024 ) { x = (x + 1023)/1024; y++; } printf("%g%s\t%s\n",int(x*10)/10,pref[y],$2); } END { y = 1; while( total > 1024 ) { total = (total + 1023)/1024; y++; } printf("Total: %g%s\n",int(total*10)/10,pref[y]); }'; }
showtree(){ find $1 -type d -print 2>/dev/null|awk '!/\.$/ {for (i=1;i<NF;i++){d=length($i);if ( d < 5  && i != 1 )d=5;printf("%"d"s","|")}print "---"$NF}'  FS='/'; }
hasip(){ dig -x $1 @224.0.0.251 -p 5353 +short; }

getCert() {
  if test -n "$1"
    then ip=$1
  else
    echo "no IP given" && return 1
  fi
  if test -n "$2"
    then port=$2
  else
    echo "no port given, asuming 443" && port=443
  fi
  echo -n | openssl s_client -connect $ip:$port | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' 2>/dev/null
}


### Bitcoin Stuff ###
kolacoins(){
    coins=$(curl http://www.bitcoincharts.com/markets/currencies/ 2> /dev/null | grep -A 1 EUR | grep -o "[0-9]*\.[0-9]*")
    mate=0.66
    current_price=$(bc <<< "scale=8;$mate/$coins")
    echo "Current Bitcoin Price: 0$current_price"
    qrencode -o ~/Desktop/kolacoins.png "bitcoin:1HG34qznjurDFe2V2wCEvQk7tK2oiHnrF5?amount=0$current_price&label=Trinkpost&message=Mate-Kola"
    echo "URL: bitcoin:1HG34qznjurDFe2V2wCEvQk7tK2oiHnrF5?amount=0$current_price&label=Trinkpost&message=Mate-Kola"; }
bitcoins(){
    coins=$(curl http://www.bitcoincharts.com/markets/currencies/ 2> /dev/null | grep -A 1 EUR | grep -o "[0-9]*\.[0-9]*")
    kohlen=$1
    test -z "$kohlen" && kohlen=1
    current_coins=$(bc <<< "scale=8;$kohlen / $coins")
    current_euros=$(bc <<< "scale=8;$kohlen * $coins")
    echo "$kohlen Bitcoin is $current_euros €"
    echo "$kohlen € are $current_coins Bitcoins"; }

btc_sell () {
    echo EUR
    for url in http://bitcoincharts.com/markets/mtgoxEUR.html http://bitcoincharts.com/markets/btcdeEUR.html http://bitcoincharts.com/markets/vcxEUR.html http://www.bitcoincharts.com/markets/localbtcEUR.html http://www.bitcoincharts.com/markets/btceEUR.html http://www.bitcoincharts.com/markets/bitcurexEUR.html
        do symbol=${url/*.*\//}
        echo $(curl $url 2>/dev/null | grep "Best Bid" | sed 's|\<p\>\<label\>Best Bid\<\/label\>\<span\>\(.*\)\</span></p>|\1|g') ${symbol/.html/}
    done | sort -nr
}

btc_buy () {
    echo EUR
    for url in http://bitcoincharts.com/markets/mtgoxEUR.html http://bitcoincharts.com/markets/btcdeEUR.html http://bitcoincharts.com/markets/vcxEUR.html http://www.bitcoincharts.com/markets/localbtcEUR.html http://www.bitcoincharts.com/markets/btceEUR.html http://www.bitcoincharts.com/markets/bitcurexEUR.html
        do symbol=${url/*.*\//}
        echo $(curl $url 2>/dev/null | grep "Best Ask" | sed 's|\<p\>\<label\>Best Ask\<\/label\>\<span\>\(.*\)\</span></p>|\1|g') ${symbol/.html/}
    done | sort -n
}

btc_markets () {
    echo EUR
    for url in http://bitcoincharts.com/markets/mtgoxEUR.html http://bitcoincharts.com/markets/btcdeEUR.html http://bitcoincharts.com/markets/vcxEUR.html http://bitcoincharts.com/markets/btceEUR.html http://bitcoincharts.com/markets/bitcurexEUR.html
        do symbol=${url/*.*\//}
        echo $(curl $url 2>/dev/null | grep "Last Trade" | sed 's|\<p\>\<label\>Last Trade\<\/label\>\<span\>\(.*\)\</span></p>|\1|g') ${symbol/.html/}
    done | sort -n
    echo USD
    for url in http://bitcoincharts.com/markets/mtgoxUSD.html http://bitcoincharts.com/markets/bitstampUSD.html http://bitcoincharts.com/markets/vcxUSD.html http://bitcoincharts.com/markets/btceUSD.html
        do symbol=${url/*.*\//}
        echo $(curl $url 2>/dev/null | grep "Last Trade" | sed 's|\<p\>\<label\>Last Trade\<\/label\>\<span\>\(.*\)\</span></p>|\1|g') ${symbol/.html/}
    done | sort -n
}
