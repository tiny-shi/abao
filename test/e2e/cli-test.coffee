chai = require 'chai'
child_process = require 'child_process'
express = require 'express'
_ = require 'lodash'
pkg = require '../../package'

expect = chai.expect

HOSTNAME = 'localhost'
PORT = 3333
SERVER = "http://#{HOSTNAME}:#{PORT}"

TEMPLATE_DIR = './templates'
DFLT_TEMPLATE_FILE = "#{TEMPLATE_DIR}/hooks.js"
FIXTURE_DIR = './test/fixtures'
RAML_DIR = "#{FIXTURE_DIR}"
HOOK_DIR = "#{FIXTURE_DIR}"
SCHEMA_DIR = "#{FIXTURE_DIR}/schemas"

CMD_PREFIX = ''
ABAO_BIN = './bin/abao'
MOCHA_BIN = './node_modules/mocha/bin/mocha'

mochaJsonReportKeys = [
  'stats',
  'tests',
  'pending',
  'failures',
  'passes'
]

stderr = ''
stdout = ''
report = ''
exitStatus = null

receivedRequest = {}

#
# To dump individual raw test results:
#
# describe('show me the results', () ->
#   runTestAsync = (done) ->
#     cmd = "#{ABAO_BIN}"
#     execCommand cmd, done
#   before (done) ->
#     debugExecCommand = true
#     runTestAsync done
#   after () ->
#     debugExecCommand = false
#
debugExecCommand = false


execCommand = (cmd, callback) ->
  stderr = ''
  stdout = ''
  report = ''
  exitStatus = null

  cli = child_process.exec CMD_PREFIX + cmd, (error, out, err) ->
    stdout = out
    stderr = err
    try
      report = JSON.parse out
    catch ignore
      # Ignore issues with creating report from output

    if error
      exitStatus = error.code

  cli.on 'close', (code) ->
    exitStatus = code if exitStatus == null and code != undefined
    if debugExecCommand
      console.log "stdout:\n#{stdout}\n"
      console.log "stderr:\n#{stderr}\n"
      console.log "report:\n#{report}\n"
      console.log "exitStatus = #{exitStatus}\n"
    callback()


describe 'Command line interface', () ->

  describe 'when run without any arguments', (done) ->

    runNoArgTestAsync = (done) ->
      cmd = "#{ABAO_BIN}"

      execCommand cmd, done

    before (done) ->
      runNoArgTestAsync done

    it 'should print usage to stderr', () ->
      firstLine = stderr.split('\n')[0]
      expect(firstLine).to.equal('Usage:')

    it 'should print error message to stderr', () ->
      expect(stderr).to.include('must specify path to RAML file')

    it 'should exit due to error', () ->
      expect(exitStatus).to.equal(1)


  describe 'when run with multiple positional arguments', (done) ->

    runTooManyArgTestAsync = (done) ->
      ramlFile = "#{RAML_DIR}/single-get.raml"
      cmd = "#{ABAO_BIN} #{ramlFile} #{ramlFile}"

      execCommand cmd, done

    before (done) ->
      runTooManyArgTestAsync done

    it 'should print usage to stderr', () ->
      firstLine = stderr.split('\n')[0]
      expect(firstLine).to.equal('Usage:')

    it 'should print error message to stderr', () ->
      expect(stderr).to.include('accepts single positional command-line argument')

    it 'should exit due to error', () ->
      expect(exitStatus).to.equal(1)


  describe 'when run with one-and-done options', (done) ->

    describe 'when RAML argument unnecessary', () ->

      describe 'when invoked with "--reporters" option', () ->

        reporters = ''

        runReportersTestAsync = (done) ->
          execCommand "#{MOCHA_BIN} --reporters", () ->
            reporters = stdout
            execCommand "#{ABAO_BIN} --reporters", done

        before (done) ->
          runReportersTestAsync done

        it 'should print same output as `mocha --reporters`', () ->
          expect(stdout).to.equal(reporters)

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


      describe 'when invoked with "--version" option', () ->

        runVersionTestAsync = (done) ->
          cmd = "#{ABAO_BIN} --version"

          execCommand cmd, done

        before (done) ->
          runVersionTestAsync done

        it 'should print version number to stdout', () ->
          expect(stdout.trim()).to.equal(pkg.version)

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


      describe 'when invoked with "--help" option', () ->

        runHelpTestAsync = (done) ->
          cmd = "#{ABAO_BIN} --help"

          execCommand cmd, done

        before (done) ->
          runHelpTestAsync done

        it 'should print usage to stdout', () ->
          firstLine = stdout.split('\n')[0]
          expect(firstLine).to.equal('Usage:')

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


    describe 'when RAML argument required', () ->

      describe 'when invoked with "--names" option', () ->

        runNamesTestAsync = (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --names"

          execCommand cmd, done

        before (done) ->
          runNamesTestAsync done

        it 'should print names', () ->
          expect(stdout).to.include('GET /machines -> 200')

        it 'should not run tests', () ->
          expect(stdout).to.not.include('0 passing')

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


      describe 'when invoked with "--generate-hooks" option', () ->

        describe 'by itself', () ->

          runGenHooksTestAsync = (done) ->
            ramlFile = "#{RAML_DIR}/single-get.raml"
            cmd = "#{ABAO_BIN} #{ramlFile} --generate-hooks"

            execCommand cmd, done

          before (done) ->
            runGenHooksTestAsync done

          it 'should print skeleton hookfile', () ->
            expect(stdout).to.include('// ABAO hooks file')

          it 'should not run tests', () ->
            expect(stdout).to.not.include('0 passing')

          it 'should exit normally', () ->
            expect(exitStatus).to.equal(0)


        describe 'with "--template" option', () ->

          runGenHookTemplateTestAsync = (done) ->
            templateFile = "#{TEMPLATE_DIR}/hookfile.js"
            ramlFile = "#{RAML_DIR}/single-get.raml"
            cmd = "#{ABAO_BIN} #{ramlFile} --generate-hooks --template #{templateFile}"

            execCommand cmd, done

          before (done) ->
            runGenHookTemplateTestAsync done

          it 'should print skeleton hookfile', () ->
            expect(stdout).to.include('// ABAO hooks file')

          it 'should not run tests', () ->
            expect(stdout).to.not.include('0 passing')

          it 'should exit normally', () ->
            expect(exitStatus).to.equal(0)


      describe 'when invoked with "--template" but without "--generate-hooks" option', () ->

        runTemplateOnlyTestAsync = (done) ->
          templateFile = "#{TEMPLATE_DIR}/hookfile.js"
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --template #{templateFile}"

          execCommand cmd, done

        before (done) ->
          runTemplateOnlyTestAsync done

        it 'should print error message to stderr', () ->
          expect(stderr).to.include('Implications failed:')
          expect(stderr).to.include('template -> generate-hooks')

        it 'should exit due to error', () ->
          expect(exitStatus).to.equal(1)


  describe 'when RAML file not found', (done) ->

    runNoRamlTestAsync = (done) ->
      ramlFile = "#{RAML_DIR}/nonexistent_path.raml"
      cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER}"

      execCommand cmd, done

    before (done) ->
      runNoRamlTestAsync done

    it 'should print error message to stderr', () ->
      # See https://travis-ci.org/cybertk/abao/jobs/76656192#L479
      # iojs behaviour is different from nodejs
      expect(stderr).to.include('Error: ENOENT')

    it 'should exit due to error', () ->
      expect(exitStatus).to.equal(1)


  describe 'arguments with existing RAML and responding server', () ->

    describe 'when invoked without "--server" option', () ->

      describe 'when RAML file does not specify "baseUri"', () ->

        runUnspecifiedServerTestAsync = (done) ->
          ramlFile = "#{RAML_DIR}/no-base-uri.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --reporter json"

          execCommand cmd, done

        before (done) ->
          runUnspecifiedServerTestAsync done

        it 'should print error message to stderr', () ->
          expect(stderr).to.include('no API endpoint specified')

        it 'should exit due to error', () ->
          expect(exitStatus).to.equal(1)


      describe 'when RAML file specifies "baseUri"', () ->

        resTestTitle = 'GET /machines -> 200 Validate response code and body'

        runBaseUriServerTestAsync = (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --reporter json"

          app = express()

          app.get '/machines', (req, res) ->
            machine =
              type: 'bulldozer'
              name: 'willy'
            res.status(200).json([machine])

          server = app.listen PORT, () ->
            execCommand cmd, () ->
              server.close()

          server.on 'close', done

        before (done) ->
          runBaseUriServerTestAsync done

        it 'should print count of tests run', () ->
          expect(report).to.exist
          expect(report).to.have.all.keys(mochaJsonReportKeys)
          expect(report.stats.tests).to.equal(1)
          expect(report.stats.passes).to.equal(1)

        it 'should print correct title for response', () ->
          expect(report.tests).to.have.length(1)
          expect(report.tests[0].fullTitle).to.equal(resTestTitle)

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


    describe 'when executing the command and the server is responding as specified in the RAML', () ->

      resTestTitle = 'GET /machines -> 200 Validate response code and body'

      runNormalTestAsync = (done) ->
        ramlFile = "#{RAML_DIR}/single-get.raml"
        cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --reporter json"

        app = express()

        app.get '/machines', (req, res) ->
          machine =
            type: 'bulldozer'
            name: 'willy'
          res.status(200).json([machine])

        server = app.listen PORT, () ->
          execCommand cmd, () ->
            server.close()

        server.on 'close', done

      before (done) ->
        runNormalTestAsync done

      it 'should print count of tests run', () ->
        expect(report).to.exist
        expect(report).to.have.all.keys(mochaJsonReportKeys)
        expect(report.stats.tests).to.equal(1)
        expect(report.stats.passes).to.equal(1)

      it 'should print correct title for response', () ->
        expect(report.tests).to.have.length(1)
        expect(report.tests[0].fullTitle).to.equal(resTestTitle)

      it 'should exit normally', () ->
        expect(exitStatus).to.equal(0)


    describe 'when executing the command and RAML includes other RAML files', () ->

      runRamlIncludesTestAsync = (done) ->
        ramlFile = "#{RAML_DIR}/include_other_raml.raml"
        cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER}"

        app = express()

        app.get '/machines', (req, res) ->
          machine =
            type: 'bulldozer'
            name: 'willy'
          res.status(200).json([machine])

        server = app.listen PORT, () ->
          execCommand cmd, () ->
            server.close()

        server.on 'close', done

      before (done) ->
        runRamlIncludesTestAsync done

      it 'should print count of tests run', () ->
        expect(stdout).to.have.string('1 passing')

      it 'should exit normally', () ->
        expect(exitStatus).to.equal(0)


    describe 'when called with arguments', () ->

      describe 'when invoked with "--reporter" option', () ->

        runReporterTestAsync = (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --reporter spec"

          app = express()

          app.get '/machines', (req, res) ->
            machine =
              type: 'bulldozer'
              name: 'willy'
            res.status(200).json([machine])

          server = app.listen PORT, () ->
            execCommand cmd, () ->
              server.close()

          server.on 'close', done

        before (done) ->
          runReporterTestAsync done

        it 'should print using the specified reporter', () ->
          expect(stdout).to.have.string('1 passing')

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


      describe 'when invoked with "--header" option', () ->

        receivedRequest = {}

        runHeaderTestAsync = (done) ->
          extraHeader = 'Accept:application/json'
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --header #{extraHeader}"

          app = express()

          app.get '/machines', (req, res) ->
            receivedRequest = req
            machine =
              type: 'bulldozer'
              name: 'willy'
            res.status(200).json([machine])

          server = app.listen PORT, () ->
            execCommand cmd, () ->
              server.close()

          server.on 'close', done

        before (done) ->
          runHeaderTestAsync done

        it 'should have an additional header in the request', () ->
          expect(receivedRequest.headers.accept).to.equal('application/json')

        it 'should print count of tests run', () ->
          expect(stdout).to.have.string('1 passing')

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


      describe 'when invoked with "--hookfiles" option', () ->

        receivedRequest = {}

        runHookfilesTestAsync = (done) ->
          pattern = "#{HOOK_DIR}/*_hooks.*"
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --hookfiles=#{pattern}"

          app = express()

          app.get '/machines', (req, res) ->
            receivedRequest = req
            machine =
              type: 'bulldozer'
              name: 'willy'
            res.status(200).json([machine])

          server = app.listen PORT, () ->
            execCommand cmd, () ->
              server.close()

          server.on 'close', done

        before (done) ->
          runHookfilesTestAsync done

        it 'should modify the transaction with hooks', () ->
          expect(receivedRequest.headers['header']).to.equal('123232323')
          expect(receivedRequest.query['key']).to.equal('value')

        it 'should print message to stdout and stderr', () ->
          expect(stdout).to.include('before-hook-GET-machines')
          expect(stderr).to.include('after-hook-GET-machines')

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


      describe 'when invoked with "--hooks-only" option', () ->

        runHooksOnlyTestAsync = (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --hooks-only"

          app = express()

          app.get '/machines', (req, res) ->
            machine =
              type: 'bulldozer'
              name: 'willy'
            res.status(200).json([machine])

          server = app.listen PORT, () ->
            execCommand cmd, () ->
              server.close()

          server.on 'close', done

        before (done) ->
          runHooksOnlyTestAsync done

        it 'should not run test without hooks', () ->
          expect(stdout).to.have.string('1 pending')

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


      describe 'when invoked with "--timeout" option', () ->

        timeout = undefined
        elapsed = -1
        finished = undefined

        runTimeoutTestAsync = (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --timeout #{timeout}"

          beginTime = undefined
          finished = false

          app = express()

          app.use (req, res, next) ->
            beginTime = new Date()
            res.on 'finish', () ->
              finished = true
            next()

          app.use (req, res, next) ->
            delay = timeout * 2
            setTimeout next, delay

          app.get '/machines', (req, res) ->
            machine =
              type: 'bulldozer'
              name: 'willy'
            res.status(200).json([machine])

          server = app.listen PORT, () ->
            execCommand cmd, () ->
              endTime = new Date()
              if finished
                elapsed = endTime - beginTime
                console.log "elapsed = #{elapsed} msecs (req/res)"
              server.close()

          server.on 'close', done


        context 'given insufficient time to complete', () ->

          before (done) ->
            timeout = 20
            console.log "timeout = #{timeout} msecs"
            runTimeoutTestAsync done

          after () ->
            finished = undefined

          it 'should not finish before timeout occurs', () ->
            expect(finished).to.be.false

          # Errors thrown by Mocha show up in stdout; those by Abao in stderr.
          it 'Mocha should throw an error', () ->
            detail = "Error: Timeout of #{timeout}ms exceeded."
            expect(stdout).to.have.string(detail)

          it 'should run test but not complete', () ->
            expect(stdout).to.have.string('1 failing')

          it 'should exit due to error', () ->
            expect(exitStatus).to.equal(1)


      describe 'when invoked with "--schema" option', () ->

        runSchemaTestAsync = (done) ->
          pattern = "#{SCHEMA_DIR}/*.json"
          ramlFile = "#{RAML_DIR}/with-json-refs.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --schemas=#{pattern}"

          app = express()

          app.get '/machines', (req, res) ->
            machine =
              type: 'bulldozer'
              name: 'willy'
            res.status(200).json([machine])

          server = app.listen PORT, () ->
            execCommand cmd, () ->
              server.close()

          server.on 'close', done

        before (done) ->
          runSchemaTestAsync done

        it 'should exit normally', () ->
          expect(exitStatus).to.equal(0)


        describe 'when expecting error', () ->

          runSchemaFailTestAsync = (done) ->
            pattern = "#{SCHEMA_DIR}/*.json"
            ramlFile = "#{RAML_DIR}/with-json-refs.raml"
            cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --schemas=#{pattern}"

            app = express()

            app.get '/machines', (req, res) ->
              machine =
                typO: 'bulldozer'       # 'type' != 'typ0'
                name: 'willy'
              res.status(200).json([machine])

            server = app.listen PORT, () ->
              execCommand cmd, () ->
                server.close()

            server.on 'close', done

          before (done) ->
            runSchemaFailTestAsync done

          it 'should exit due to error', () ->
            expect(exitStatus).to.equal(1)

