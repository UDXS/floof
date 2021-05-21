/*
    Floof Chip Development Kit

    Test Runner Framework
*/

const path = require("path");
const fs = require("fs");
const exec = require("child_process").exec;
const execSync = require("child_process").execSync;
const { stderr } = require("process");

class FloofTest {
    constructor(name) {
        this.name = name;
        this.cpp = [];
        this.verilog = [];
        console.log("Anf Floof CDK Test Runner Framework")
        console.log(`Test "${name}"`);
    }

    addCpp(file) {
        this.cpp.push(file);
        console.log(`\tCPP: ${file}`);
        return this;
    }

    addVerilog(file) {
        this.verilog.push(file);
        console.log(`\tV: ${file}`);
        return this;
    }



    get commandYosys() {
        let subcommands = "";
        for (let file of this.verilog) {
            subcommands += ` read_verilog "${file}";`;
        }
        subcommands += ` write_cxxrtl "${path.join(process.cwd(), "build/rtl.h")}"`;


        let command = `yosys -p '${subcommands}'`;
        console.log(command);
        return command;
    }

    get commandCPP() {
        let command = "clang -g -O0 -std=c++17 -I `yosys-config --datdir`/include "
        for (let file of this.cpp) {
            command += ` build/${file}`
        }
        command += ` -lstdc++ -lm -o build/${this.name}`;
        console.log(command)
        return command;
    }

    showWarningsYosys(output) {
        let lines = output.split("\n");
        for (let line of lines) {
            if (line.indexOf("Warning:") != -1) console.log(line)
        }
    }

    showErrorsYosys(output) {
        let lines = output.split("\n");
        for (let line of lines) {
            if (line.indexOf("ERROR:") != -1) console.log(line)
        }
    }

    build(callback) {
        if (fs.existsSync("build"))
            fs.rmSync("build", { force: true, recursive: true })
        fs.mkdirSync("build")


        console.log("Building with Yosys...");
        exec(this.commandYosys, {cwd: "../../rtl"}, (e, stdout, stderr) => {
            fs.writeFileSync("build/yosys.txt", stdout + "\n" + stderr);
            this.showWarningsYosys(stdout);
            this.showErrorsYosys(stderr);
            if (stderr.length == 0) {
                console.log("Copying C++ files...");
                for (let file of this.cpp) {
                    fs.copyFileSync(file, `build/${file}`)
                }
                console.log("Building with Clang...");
                let cppOut = exec(this.commandCPP, (e, stdout, stderr) => {
                    fs.writeFileSync("build/cpp.txt", stdout + "\n" + stderr);
                    console.log(stdout, stderr);
                    if (stderr.length == 0)
                        callback();
                })
            }
        })
    }

    run() {
        console.log(`Anf Floof CDK Test "${this.name}":`)
        let output = execSync(`build/${this.name}`).toString("utf8");
        fs.writeFileSync("build/output.txt", output);
        console.log(output);
    }

    buildAndRun() {
        this.build(() => this.run());
    }

}

module.exports = FloofTest;