const http = require('http');
const url = require('url');

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const { pathname } = parsedUrl;

  // extract the word from the URL path
  const word = pathname.slice(1);

  const isPalindrome = checkIfPalindrome(word);
  const response = isPalindrome ? 'yes' : 'no';

  res.end(response);
});

server.listen(3000, ()=> console.log('Server started on port 3000'));

function checkIfPalindrome(word) {
  // convert the word to lowercase and remove all non-alphanumeric characters
  const cleanedWord = word.toLowerCase().replace(/[^a-z0-9]/g, '');

  // check if the word is the same forwards and backwards
  return cleanedWord === cleanedWord.split('').reverse().join('');
}
