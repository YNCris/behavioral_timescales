function documents = transformText_mask(str,startToken,stopToken,maskToken)

str = strip(replace(str,""," "));
str = strip(replace(str,"-",maskToken));
str = startToken + str + stopToken;
documents = tokenizedDocument( ...
    str,CustomTokens=[startToken stopToken maskToken]);

end