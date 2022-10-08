const express = require("express");
const path = require("path");
const env = process.env.NODE_ENV || "development";
const app = express();

async function initServer() {
  try {
    app.listen(3000, () => {
      console.log("Server listening on port 3000...");
    });
    app.set("view engine", "html");
    app.set("views", path.join(__dirname, ""));
    app.use(express.static(path.join(__dirname, "")));
  } catch (error) {
    console.log(error);
  }
}

initServer();

module.exports = {
  app,
};
