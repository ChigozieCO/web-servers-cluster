## Deploying a cluster of web servers

This is an improvement of the [single web server architecture.](https://github.com/TheGozie/single-web-server)

We are making some changes to the code and adding more servers to make the infrastructure more resilent.

For a cleaner and a better readable code we will add a variables file that will hold our variables to make our code more compliant with the "Don’t Repeat Yourself (DRY) principle" where every piece of knowledge must have a single, unambiguous, authoritative representation within a system.

We also add an output file to output some parameters after terraform has finished building our infrastructure.

A single server is a single point of failure. If that server crashes, or if it becomes overloaded from too much traffic, users will be unable to access your site. This modification solution will run a cluster of servers, routing around servers that go down, and adjusting the size of the cluster up or down based on traffic.

We would configure Auto Scaling Group (ASG) to manage the cluster of web servers. An ASG takes care of a lot of tasks for you completely automatically, including launching a cluster of EC2 Instances, monitoring the health of each Instance, replacing failed Instances, and adjusting the size of the cluster in response to load.

I have decided to use a launch configuration here instead of the AWS best practice to use a launch template because it's easier to use in some conceptrs of zero-doewntime deployment. 