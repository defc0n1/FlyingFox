    <html>
    <head>
    </head>
    <body>
    <div id="main"></div>
    </body>
    <script>

function set_interval(l2, f, t) {
    if (lock_status == l2){
	f();
	setTimeout(function(){set_interval(l2, f, t)}, t);
    }
};
function interval_unlocked(f, t) { set_interval("unlocked", f, t); };//this function is so that when we change back to locked mode, all the threads that we don't need turn off.
function unlocked() {
    var div = document.getElementById("main");
    div.innerHTML = "";
    
    refresh_server_status();
    window.setInterval(refresh_server_status, 10000);
    refresh_inbox_peers();
    window.setInterval(refresh_inbox_peers, 20000);
    refresh_channel_peers();
    window.setInterval(refresh_channel_peers, 5000);
    setTimeout(refresh_channel, 3000);//after a short delay, that way we are sure server_status is ready
    window.setInterval(refresh_channel, 5000);
    refresh_mail_nodes();
    window.setInterval(refresh_mail_nodes, 10000);
    refresh_txs();
    window.setInterval(refresh_txs, 2000);
    

    var x = document.createElement("font");
    x.id = "pub";
    div.appendChild(x);
    refresh_status();
    interval_unlocked(refresh_status, 2000);

    var x = document.createElement("font");
    x.id = "bal";
    div.appendChild(x);
    setTimeout(refresh_my_balance, 1000);
    interval_unlocked(refresh_my_balance, 5000);
    
    var x = document.createElement("font");
    x.id = "cbal";
    div.appendChild(x);
    refresh_channel_balance();
    interval_unlocked(refresh_channel_balance, 5000);
    
    var x = document.createElement("font");
    x.id = "reg";
    x.innerHTML = "registration status: not registered<br>";
    div.appendChild(x);
    
    var x = document.createElement("font");
    var t = document.createTextNode("partner's pubkey: ");
    x.appendChild(t);
    div.appendChild(x);
    
    var x = document.createElement("textarea");
    var t = document.createTextNode("BOyZPCA8xuXNaxmqSZaTHPumJiOY8TWt23LjTWLGk1PGY178HeCqY82qY4YAX01zcLrFREdiDv33TlL8VxG9ws0");
    x.id = "other";
    x.rows = "1";
    x.cols = "80";
    x.appendChild(t);
    div.appendChild(x);
    refresh_inbox_size();
    interval_unlocked(refresh_inbox_size, 1000);

    var x = document.createElement("button");
    x.type = "button";
    x.id = "switch_partner";
    var t = document.createTextNode("Switch Partner");
    x.appendChild(t);
    div.appendChild(x);
    peer_id = 0;
    x.onclick=function() {
	peer_id = (peer_id + 1) % inbox_peers.length;
	if (inbox_peers.length > 0){document.getElementById("other").value = inbox_peers[peer_id];};
    };

   
    var x = document.createElement("br");
    div.appendChild(x);
    
    var x = document.createElement("textarea");
    x.id = "msg";
    x.rows = 6;
    x.cols = 80;
    div.appendChild(x);

    var x = document.createElement("button");
    x.type = "button";
    x.id = "send_button";
    var t = document.createTextNode("Send Message");
    x.appendChild(t);
    div.appendChild(x);
    document.getElementById("send_button").onclick=function() {
	var msg = document.getElementById("msg").value;
	pub = document.getElementById("other").value;
	var node = JSON.stringify(server());
	msg = JSON.stringify(msg);
	URL = "send_message&".concat(node).concat("&").concat(pub).concat("&").concat(msg);
	//console.log("url ".concat(URL));
	local_get(URL);
	document.getElementById("msg").value = "";
    };

    var x = document.createElement("br");
    div.appendChild(x);

    var x = document.createElement("ul");
    x.id = "messages";
    x.style = "list-style: none; padding: 0; margin: 0;";
    div.appendChild(x);

    interval_unlocked(refresh_messages_3, 1000);
    // window.setInterval(refresh_messages_3, 1000);
    setTimeout(register_1, 4000);

    var x = document.createElement("br");
    div.appendChild(x);

    var x = document.createElement("button");
    x.type = "button";
    x.id = "delete";
    var t = document.createTextNode("Delete Messages");
    x.appendChild(t);
    div.appendChild(x);
    document.getElementById("delete").onclick=function() {
	pub = document.getElementById("other").value;
	URL = "delete_all_messages&".concat(pub);
	local_get(URL);
	refresh_messages();
    };

    var x = document.createElement("button");
    x.type = "button";
    var t = document.createTextNode("Lock");
    x.appendChild(t);
    div.appendChild(x);
    x.onclick=function() {
	local_get("lock");
	// locked();
	refresh_page();
    };
};
//setTimeout(unlocked, 1000);
function locked() {
    console.log("locked function");
    var div = document.getElementById("main");
    div.innerHTML = "";

    var x = document.createElement("font");
    var t = document.createTextNode("passphrase to unlock: ");
    x.appendChild(t);
    div.appendChild(x);

    var x = document.createElement("textarea");
    x.id = "passphrase";
    x.rows = "1";
    x.cols = "80";
    div.appendChild(x);

    var x = document.createElement("button");
    x.type = "button";
    var t = document.createTextNode("Unlock");
    x.appendChild(t);
    div.appendChild(x);
    x.onclick=function() {
	passphrase = document.getElementById("passphrase").value;
	local_get("unlock&".concat(passphrase));
	refresh_page();
    };

    var x = document.createElement("button");
    x.type = "change_password";
    var t = document.createTextNode("ChangePassword");
    x.appendChild(t);
    div.appendChild(x);
    x.onclick=function() {
	change_password();
    };
};
function change_password() {
    console.log("change_password function");
    var div = document.getElementById("main");
    div.innerHTML = "";

    var x = document.createElement("font");
    var t = document.createTextNode("old passphrase: ");
    x.appendChild(t);
    div.appendChild(x);
    var x = document.createElement("textarea");
    x.id = "old";
    x.rows = "1";
    x.cols = "80";
    div.appendChild(x);

    var x = document.createElement("br");
    div.appendChild(x);

    var x = document.createElement("font");
    var t = document.createTextNode("new passphrase: ");
    x.appendChild(t);
    div.appendChild(x);
    var x = document.createElement("textarea");
    x.id = "new";
    x.rows = "1";
    x.cols = "80";
    div.appendChild(x);

    var x = document.createElement("br");
    div.appendChild(x);

    var x = document.createElement("font");
    var t = document.createTextNode("confirm new passphrase: ");
    x.appendChild(t);
    div.appendChild(x);
    var x = document.createElement("textarea");
    x.id = "confirm";
    x.rows = "1";
    x.cols = "80";
    div.appendChild(x);

    var x = document.createElement("br");
    div.appendChild(x);

    var x = document.createElement("button");
    x.type = "button";
    var t = document.createTextNode("Update Passphrase");
    x.appendChild(t);
    x.onclick=function() {
	old = document.getElementById("old").value;
	new_pass = document.getElementById("new").value;
	confirm_pass = document.getElementById("confirm").value;
	if (new_pass === confirm_pass) {
	    local_get("change_password_key&".concat(old).concat("&").concat(new_pass));
	};
    };
    div.appendChild(x);

    var x = document.createElement("button");
    x.type = "button";
    var t = document.createTextNode("cancel");
    x.appendChild(t);
    x.onclick=function() {
	locked();
	//refresh_page();
    };
    div.appendChild(x);
};
function empty() {
    var div = document.getElementById("main");
    div.innerHTML = "";

    var x = document.createElement("font");
    var t = document.createTextNode("passphrase to unlock: ");
    x.appendChild(t);
    div.appendChild(x);

    var x = document.createElement("textarea");
    x.id = "passphrase";
    x.rows = "1";
    x.cols = "80";
    div.appendChild(x);

    var x = document.createElement("br");
    div.appendChild(x);

    var x = document.createElement("font");
    var t = document.createTextNode("confirm passphrase: ");
    x.appendChild(t);
    div.appendChild(x);

    var x = document.createElement("textarea");
    x.id = "confirm";
    x.rows = "1";
    x.cols = "80";
    div.appendChild(x);

    var x = document.createElement("button");
    x.type = "button";
    var t = document.createTextNode("Unlock");
    div.appendChild(x);
    x.onclick=function() {
	passphrase = document.getElementById("passphrase").value;
	confirm = document.getElementById("confirm").value;
	if (passphrase === confirm) {
	    local_get("change_password_key&".concat("").concat("&").concat(passphrase));
	};
    };

};


// we need a function for loading new pub/priv pairs into the node.
function url(port, ip) { return "http://".concat(ip).concat(":").concat(port.toString().concat("/")); }
PORT = 46666;
my_port = 46666;
function xml_check(x) { return ((x.readyState === 4) && (x.status === 200)); };
function xml_out(x) { return x.responseText; }
function refresh_helper(x, callback) {
    if (xml_check(x)) {callback();}
    else {setTimeout(function() {refresh_helper(x, callback);}, 1000);}
};
function getter(t, u, callback){
    t = JSON.stringify(t);
    u = u.concat(btoa(t));
    var xmlhttp=new XMLHttpRequest();
    xmlhttp.onreadystatechange = callback;
    xmlhttp.open("GET",u,true);
    xmlhttp.send(null);
    return xmlhttp
}
function get(t, callback) {
    u = url(my_port, "localhost");
    return getter(t, u, callback);
}
function server() {return {"ip":"45.55.5.85","port":PORT,"__struct__":"Elixir.Peer"}};
function server_get(t, callback) {
    s = server();
    u = url(s.port, s.ip);
    return getter(t, u, callback);
}
function local_get(t, callback) {
    u = url(my_port + 1000, "localhost");
    u = u.concat("priv/");
    return getter(t, u, callback);
}
function empty_messages() {
    var ul = document.getElementById("messages");
    ul.innerHTML = "";
}

my_status = {};
function refresh_status() {
    var x = get("status");
    refresh_helper(x, function(){ my_status = JSON.parse(xml_out(x)); });
    document.getElementById("pub").innerHTML = "pubkey: ".concat(my_status.pubkey).concat("<br>");
};

server_status = {};
function refresh_server_status() {
    var x = server_get("status");
    refresh_helper(x, function(){ server_status = JSON.parse(xml_out(x));});
};

inbox_peers = [];
function refresh_inbox_peers() {
    var x = local_get("inbox_peers");
    refresh_helper(x, function(){ inbox_peers = JSON.parse(JSON.parse(xml_out(x)));});
};

network_peers = [];
function refresh_network_peers() { //unused at this time.
    var x = get("all_peers");
    refresh_helper(x, function(){ network_peers = JSON.parse(xml_out(x));});
};

inbox_size = -1;
function refresh_inbox_size() {
    pub = document.getElementById("other").value;
    var x = local_get("inbox_size&".concat(pub));
    refresh_helper(x, function(){
	old_size = inbox_size;
	inbox_size = xml_out(x);
	if (old_size !== inbox_size) { refresh_messages(); };
    });
};

channel_peers = [];
function refresh_channel_peers() {
    var x = local_get("channel_peers");
    refresh_helper(x, function(){ channel_peers = JSON.parse(xml_out(x));});
};

channel_balance = -1;
function refresh_channel_balance() {
    var x = local_get("channel_balance&".concat(server_status.pubkey));
    refresh_helper(x, function(){ channel_balance = xml_out(x);});
    document.getElementById("cbal").innerHTML = "channel balance: ".concat(channel_balance).concat("<br>");
};

my_balance = -1;
function refresh_my_balance() {
    var x = get("kv&".concat(my_status.pubkey));
    refresh_helper(x, function(){ my_balance = JSON.parse(xml_out(x)).amount;});
    document.getElementById("bal").innerHTML = "balance: ".concat(my_balance).concat("<br>");
};

channel = "nil";
function refresh_channel() {
    var x = local_get("channel_get&".concat(server_status.pubkey));
    refresh_helper(x, function(){ channel = JSON.parse(JSON.parse(xml_out(x)));});
};

mail_nodes = [];
function refresh_mail_nodes() {
    var x = get("mail_nodes")
    refresh_helper(x, function(){ mail_nodes = JSON.parse(JSON.parse(xml_out(x)));});
};

txs = [];
function refresh_txs() {
    var x = get("txs");
    refresh_helper(x, function(){ txs = JSON.parse(xml_out(x)); });
};

lock_status = "";
function refresh_lock_status() {
    var x = local_get("key_status");
    refresh_helper(x, function(){ lock_status = JSON.parse(xml_out(x)); });
};

function refresh_page_status_helper() {
    page_status = lock_status;
    console.log("refresh page status helper ".concat(page_status));
    if (page_status == "locked") { locked() };
    if (page_status == "unlocked") { unlocked() };
    if (page_status == "empty") { empty() };
};
function refresh_page_status() {
    if (page_status !== lock_status) {
	refresh_page_status_helper();
    };
};
function lockwait(x, maxtimes){
    console.log("lockwait");
    if (maxtimes < 1) {
	false
    } else if (lock_status == x) {
	refresh_lock_status();
	window.setTimeout(function(){lockwait(x, maxtimes - 1);}, 100);
    } else {
	refresh_page_status_helper();
    };
};
function refresh_page() { lockwait(lock_status, 50); };
refresh_page();



messages = [];
function refresh_messages() {
    messages = [];
    console.log("refresh messages");
    for (i = 0; i < inbox_size; i++) {
	refresh_messages_2(i);
    };
};
function refresh_messages_2(i) {
    pub = document.getElementById("other").value;
    var x = local_get("read_message&".concat(i).concat("&").concat(pub));
    refresh_helper(x, function(){
	msg = JSON.parse(JSON.parse(xml_out(x)));
	messages[inbox_size - i] = msg;
    });
};
function add_message(message) {
    var ul = document.getElementById("messages");
    var li = document.createElement("li");
    li.innerHTML = '<font color="#000000">'.concat(message).concat('</font>');
    ul.appendChild(li);
}
function recieve_message(message) {
    var ul = document.getElementById("messages");
    var li = document.createElement("li");
    li.innerHTML = '<font color="#FF0000">____'.concat(message).concat('</font>');
    ul.appendChild(li);
}
function refresh_messages_3() {
    pub = document.getElementById("other").value;
    empty_messages();
    messages.map(function(m) {
	if (m === undefined)  { false; }
	else if (m.to == pub) { add_message(m.msg); }
	else                  { recieve_message(m.msg); }
    });
};

function to_channel(pub, amount) {
    x = local_get("to_channel&".concat(pub).concat("&").concat(amount));
    refresh_helper(x, function(){ return "success";});
};
function register() {
    x = local_get("register&".concat(JSON.stringify(server())));
    refresh_helper(x, function(){return xml_out(x) ;} );
};

function register_1() {
    //did we make the channel yet? if not, make it, and update registeration status. recurse.
    s = server_status;
    pub = s.pubkey;
    s = my_status;
    my_pub = s.pubkey;
    if (channel == "nil") {
	amount = 10000000;
	txss = txs.filter(function (tx) {
	    return tx.data.__struct__ == "Elixir.ToChannel";
	});
	txss = txss.filter(function (tx) {
	    return tx.data.pub == my_pub;
	});
	if (txss.length == 0) { // tx isn't in txs
	    console.log("create channel");
	    to_channel(pub, Math.min(amount, my_balance - 10000));
	}
    }
    document.getElementById("reg").innerHTML = "registration status: wait for next block".concat("<br>");
    return register_2(pub);
}

function register_2(pub) {
    // is the channel ready to use yet? if not, wait a while, then recurse.
    // did we register the mailnode yet? if not, do it, and update registration status and exit.
    if (channel == "nil") {
	setTimeout(function() {register_2(pub);}, 3000);
    } else if (mail_nodes.length == 0) {
	console.log("mail node needs to be registered");
	register();
	document.getElementById("reg").innerHTML = "registartion status: registered".concat("<br>");
    } else {
	console.log("mail node works");
	document.getElementById("reg").innerHTML = "registered".concat("<br>");
    }
}

</script>
    </html>