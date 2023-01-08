import React, { ChangeEvent, useState } from "react";
import { useSearchParams } from "react-router-dom";
import logo from "./logo.svg";
import "./App.css";

function App() {
  let [userInput, setUserInput] = useState("");
  let [isPalindrom, setPalindrom] = useState("");
  let [searchParams, SetSearchParams] = useSearchParams("");

  let searchTerm = searchParams.get("word");

  let checkByUrl = () => {
    if (searchTerm != null) {
      SetSearchParams(searchTerm);
      setUserInput(searchTerm);
      let word = searchTerm;
      let re = /[\W_]/g;
      let wordLower = word.toLowerCase().replace(re, "");
      let reverseWord = wordLower.split("").reverse().join("");
      console.log(reverseWord, wordLower);
      if (reverseWord === wordLower) {
        setPalindrom(
          "The word is Palindrom! " + wordLower + " = " + reverseWord
        );
        return reverseWord === wordLower;
      } else {
        setPalindrom(
          "The word is Not Palindrom! " + wordLower + " X " + reverseWord
        );
        return reverseWord === wordLower;
      }
    }
  };

  let checkPalindrom = () => {
    let word = userInput;
    let re = /[\W_]/g;
    let wordLower = word.toLowerCase().replace(re, "");
    let reverseWord = wordLower.split("").reverse().join("");
    console.log(reverseWord, wordLower);
    if (reverseWord === wordLower) {
      setPalindrom("The word is Palindrom! " + wordLower + " = " + reverseWord);
      return reverseWord === wordLower;
    } else {
      setPalindrom(
        "The word is Not Palindrom! " + wordLower + " X " + reverseWord
      );
      return reverseWord === wordLower;
    }
  };

  let getInput = (e: ChangeEvent<HTMLInputElement>) => {
    let newVinInput = e.target.value;
    setUserInput(newVinInput);
    // e.target.value = " "
  };
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Please insert a word and i will tell you if it is a palindrom or not ?
        </p>
        <input
          type="text"
          className="InptWord"
          placeholder="Insert a word..."
          onChange={(e) => {
            getInput(e);
          }}
        />
        <button
          className="btnCheck"
          onClick={() => {
            checkPalindrom();
          }}
        >
          Check Word
        </button>
        <button
          className="btnCheck"
          onClick={() => {
            checkByUrl();
          }}
        >
          Check by URL param
        </button>
        <div>
          <p>{isPalindrom}</p>
        </div>
        {/* <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a> */}
      </header>
    </div>
  );
}

export default App;
