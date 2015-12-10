#!/bin/bash
# TODO
# lista com png's com diffs e historico
# fazer instalador para app

HASHURL=`date | sed 's/ //g' | sed 's/\://g' | perl -ne 'print lc'`

echo "$HOMOLOG"
echo "$HASHURL"

if [ "$1" != "q" ]; then
  echo "diff produção"
  echo 'page to png'
  #echo 'depencias ==> jquery'
fi

if [ -f jquery.min.js  ]; then
	echo 'jquery existe no diretorio'
else
	wget https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js -q | xargs > /tmp/phantomjs-homolog-jquery.js
fi

echo '//////////////////////////////////////'
echo '/ Escolha o ambiente de homologação  /'
echo '/ 1 => master1                       /'
echo '/ 2 => master2                       /'
echo '/ 3 => master3                       /'
echo '/ 4 => local                         /'
echo '//////////////////////////////////////'

echo 'AMBIENTE: '; read HOMOLOG

if [ "$HOMOLOG" -eq 1 ]; then
        sudo echo "var urlTest='http://master1.designeparatodos.com.br?lb=0&${HASHURL}'.toString();" >> /tmp/phantomjs-homolog.js
elif [ "$HOMOLOG" -eq 2 ]; then
        sudo echo "var urlTest='http://master2.designeparatodos.com.br?lb=0&${HASHURL}'.toString();" >> /tmp/phantomjs-homolog.js
elif [ "$HOMOLOG" -eq 3 ]; then
	sudo echo "var urlTest='http://master3.designeparatodos.com.br?lb=0&${HASHURL}'.toString();" >> /tmp/phantomjs-homolog.js
else
	echo 'Digite o dns local: '
	read HOMOLOG
	sudo echo "var urlTest='${HOMOLOG}'.toString();" >> /tmp/phantomjs-homolog.js 
fi

#gedit /tmp/phantomjs-homolog.js&

sudo cat >> /tmp/phantomjs-homolog.js << 'EOF'
var webPage = require('webpage');
var page = webPage.create();

page.viewportSize = { width: 1366, height: 1080 };
  window.setTimeout(function () {
	page.open(urlTest, function start(status) {
	    //console.log(status, '-----' ,  urlTest);
	    if(!window.jQuery){
	      phantom.injectJs('/tmp/phantomjs-homolog-jquery.js');
	    }else{console.log('not jquery')}
	    page.render('/tmp/phantomjs-homolog.png', {format: 'png', quality: '100'});
	    phantom.exit();
	});
  }, 5000);
EOF

sudo cat > /tmp/phantomjs-prod.js << 'EOF'

var webPage = require('webpage');
var page = webPage.create();

page.viewportSize = { width: 1366, height: 1080 };
page.open("http://www.oppa.com.br?lb=0", function start(status) {
   window.setTimeout(function () {
      //console.log('page open produção');
      page.render('/tmp/phantomjs-prod.png', {format: 'png', quality: '100'});
      //console.log('page render');
      phantom.exit();
   }, 2000);
});

EOF

if [ "$1" != "q" ]; then
	echo 'gerando png homolog'
fi

if [ -f /tmp/phantomjs-prod.js ]; then
	#phantomjs --ignore-ssl-errors=true --disk-cache=false --ssl-protocol=any /tmp/phantomjs-homolog.js	
        sudo phantomjs /tmp/phantomjs-homolog.js

else
	echo 'erro na criacao do phantomjs-prod.js'
	exit 1
fi

if [ "$1" != "q" ]; then
	echo 'gerando png prod'
fi

if [ -f /tmp/phantomjs-homolog.js ]; then
	#phantomjs --ignore-ssl-errors=true --disk-cache=false --ssl-protocol=any /tmp/phantomjs-prod.js
	sudo phantomjs /tmp/phantomjs-prod.js
else
	echo 'erro na criacao do phantomjs-homolog.js'
	exit 1
fi


if [ "$1" != "q" ]; then
	echo 'imagens geradas'
	echo 'cropping imagens'
fi

sudo convert -crop 1366x5000+0x0 /tmp/phantomjs-prod.png /tmp/phantomjs-prod-crop.png
sudo convert -crop 1366x5000+0x0 /tmp/phantomjs-homolog.png /tmp/phantomjs-homolog-crop.png

if [ "$1" != "q" ]; then
	echo 'gerando o diff das imagens'
fi

sudo compare -verbose /tmp/phantomjs-homolog-crop.png /tmp/phantomjs-prod-crop.png /tmp/difference.png

if [ "$1" != "q" ]; then
	echo 'excluindo arquivos temporários'
fi

sudo rm -rf /tmp/phantomjs-homolog*
sudo rm -rf /tmp/phantomjs-prod*

if [ "$1" != "q" ]; then
	echo 'diff criada'
fi
sudo eog /tmp/difference.png&

echo 'Gerando Log'
echo 'add test log ${date} ambiente de teste: ${HOMOLOG} <===> produção' >> difflog.txt 
