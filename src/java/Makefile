jar: wikitopics.jar

wikitopics.jar: class/Convert.class class/Redirect.class class/Trends.class
	jar cvf wikitopics.jar -C class .

class/Convert.class: src/Convert.java
	javac -d class src/Convert.java

class/Redirect.class: src/Redirect.java
	javac -d class src/Redirect.java

class/Trends.class: src/Trends.java
	javac -d class src/Trends.java
