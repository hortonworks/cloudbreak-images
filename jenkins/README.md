Jenkins jobs for cloudbreak-images
==================================

* Edit jenkins_jobs.ini and add jenkins parameters

* Install jenkins-job-builder
  ```shell
  pip install jenkins-job-builder
  ```

* Test jenkins jobs
  ```shell
  jenkins-jobs --conf jenkins_jobs.ini test cloudbreak.yaml
  ```

* Create jenkins jobs
  ```shell
  jenkins-jobs --conf jenkins_jobs.ini update cloudbreak.yaml
  ```
