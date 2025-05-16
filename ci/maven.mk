test:
	mvn test --batch-mode

clean:
	mvn clean

package:
	mvn package --batch-mode -Ddocker-repository=$(docker-repository)

quality-scan:
	# mvn sonar:sonar --batch-mode -Dsonar.host.url=$(sonarqube-url) -Dsonar.token=$(sonarqube-token)

version-apply:
	mvn versions:set -DnewVersion=$(VERSION)
