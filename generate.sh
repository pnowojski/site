 for f in _posts/*; do TITLE=`cat $f | grep '^title:' | sed 's/^title: //'`  ; echo $TITLE; done

