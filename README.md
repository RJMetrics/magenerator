# magenerator
Generate sample Magento store data

Repo Owner: Ben Garvey
Owned by Magento

# Setup
If you don't have node, npm, or coffeescript installed
```
sudo apt-get update
sudo apt-get install nodejs
sudo apt-get install npm
sudo npm install -g coffee-script
```

Then in the magenerator directory
```
npm install chance
npm install adj-noun
npm install random-date
```

# Running
```
coffee generate.coffee
```

The data files are generated and placed in the data directory
