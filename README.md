This project is deeply inspired by Vaprobash: https://github.com/fideloper/Vaprobash
and [Wes Roberts](http://github.com/jchook) ([@jchook](http://github.com/jchook))

	$ curl -L https://goo.gl/OYzBFy > Vagrantfile && curl -L https://goo.gl/Ktv03C > provision.sh && curl -L https://goo.gl/HTNNJi > hostfile.sh

Edit `Vagrantfile` and `provision.sh` to fit project requirements (by default, the combination of letters that forms the name of the directory for the htdocs is spelled "public," to refer to where the webserver reads your hypertext documents)

	$ vagrant up
