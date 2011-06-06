(function($){$.extend({password:function(length,digits,special){var iteration=0;var password="";var randomNumber;if(length==undefined){var length=8;}
if(digits==undefined){var digits=0;}
if(special==undefined){var special=false;}
while(iteration<length){if(digits!=0){password+=(Math.floor((Math.random()*100))%10);digits-=1;}else{randomNumber=(Math.floor((Math.random()*100))%94)+33;if(!special){if((randomNumber>=33)&&(randomNumber<=47)){continue;}
if((randomNumber>=58)&&(randomNumber<=64)){continue;}
if((randomNumber>=91)&&(randomNumber<=96)){continue;}
if((randomNumber>=123)&&(randomNumber<=126)){continue;}}
password+=String.fromCharCode(randomNumber);}
iteration++;}
return password;}});})(jQuery);