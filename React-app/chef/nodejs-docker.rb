# Install Docker
package 'docker' do
    action :install
  end
  
  # Start Docker service
  service 'docker' do
    action [:enable, :start]
  end
  
  # Pull the specified Docker image
  execute 'pull_react_palindrome_url_image' do
    command 'docker pull idoh9/nodejs-palindrome:latest'
  end
  
  # Run the Docker image on port 80
  execute 'run_react_palindrome_url_image' do
    command 'docker run -p 3000:3000 idoh9/nodejs-palindrome:latest'
  end
  
  # Install nginx
  package 'nginx' do
    action :install
  end
  
  # Start nginx service
  service 'nginx' do
    action [:enable, :start]
  end
  