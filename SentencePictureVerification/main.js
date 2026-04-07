PennController.ResetPrefix(null); // Shorten command names (keep this line here))

DebugOff()   // Uncomment this line only when you are 100% done designing your experiment

    // We use the native-Ibex "DashedSentence" controller
    // Documentation at:   https://github.com/addrummond/ibex/blob/master/docs/manual.md#dashedsentence

// First show instructions, then experiment trials, send results and show end screen
Sequence("counter","welcome","instructions","practice","experiment","demographics",SendResults(),"end")

// This is run at the beginning of each trial
Header(
    // Declare global variables for Prolific ID, Group, and Counter
    newVar("ID").global()
    ,
    newVar("practiceOrder", 0).global()
)
// Set Counter
SetCounter("counter","inc",1)
//SetCounter("counter",0)

// Welcome
newTrial("welcome",
    // Automatically print all Text elements, centered
    defaultText.center().print()
    ,
    newText("<p style='font-size: 19px;'>Please verify in your Prolific ID below, ensure your Prolific ID is accurate and there are no typos.</p>")
    ,
    newText("<p style='font-size: 19px;'>Then click the Start button to start the experiment.</b>")
    ,
    newTextInput("inputID", "")
        .center()
        .css("margin","1em")    // Add a 1em margin around this element
        .print()
    ,
    newButton("Start")
        .center()
        .print()
    // Only validate a click on Start when inputID has been filled
    .wait(getTextInput("inputID").testNot.text(""))
    ,
    // Store the text from inputID into the Var element
    getVar("ID").set(getTextInput("inputID"))
)
newTrial("instructions",
    // Automatically print all Text elements, centered
    defaultText.center().print()
    ,
    newText("<h1>Welcome!</h1>")
    ,
    newText("<p style='font-size: 19px;'>For this task, you will read about 50 English sentences word by word. Click the spacebar to proceed from one word to the next.</p>")
    ,
    newText("<p style='font-size: 19px;'>Please read each sentence carefully, at your normal reading speed. Each word will disappear after you have read it.</p>")
    ,
    newText("<p style='font-size: 19px;'>After you are done reading each sentence, you will see an image and you will need to determine if the sentence is true or false in relation to the image by clicking a button on your keyboard.</p>")
    ,
    newText("<p style='font-size: 19px;'>You will have an opportunity to practice, before starting the experiment.</p>")
    ,
    newText("<p style='font-size: 19px;'>Are you ready?</p>")
    ,
    newButton("b1","Continue")
        .center()
        .print()
        .wait()
)
// Practice
Template("practice_stimuli.csv", row =>
    newTrial("practice",
        defaultText.center().print()
        ,
        getVar("practiceOrder").test.is(0)
            .success(newText("practice-instructions","<p style='font-size: 19px;'>Click the spacebar to proceed from one word to the next</p>")
                    ,newText("instr-cont","<p style='font-size: 19px;'>Then determine if the sentence is true or false in relation to the image.</p>")
                    ,newText("success","<p style='font-size: 19px;'>"+row.instructions+"</p>")
                    ,newButton("Start Practice").center().print().wait().remove()
                    ,getText("practice-instructions").remove()
                    ,getText("instr-cont").remove()
                    ,getText("success").remove()
            )
        ,
        newController("DashedSentence", {s : row.sentence})
            .center()
            .print()
            .wait()
            .remove()
        ,
        newText("inst1", "<p style='font-size: 19px;'>"+row.instructions+"</p>")
        ,
        newImage("img1", row.image)
            .size(888.89, 500)
            .center()
            .print()
        ,
        newKey("key1","AL")
            .log()
            .wait()
        ,
        getVar("practiceOrder").set(v=>v+1)
        ,
        getVar("practiceOrder").test.is(2)
            .success(getText("inst1").remove()
                    ,getImage("img1").remove()
                    ,newText("practice-end","<p style='font-size: 19px;'>That's the end of the practice round.</p>")
                    ,newText("reminder","<p style='font-size: 19px;'><b>Please remember: </b>"+row.instructions+"</p>")
                    ,newText("<p style='font-size: 19px;'>These instructions will no longer be repeated.</p>")
                    ,newButton("Start Experiment").center().print().wait().remove()
                    ,getText("practice-end").remove()
                    ,getText("reminder").remove()
                    ,getText("success").remove()
            )
    )
)
// Main Experiment
Template("full_stimuli.csv", row =>
    newTrial("experiment",
        newController("DashedSentence", {s : row.sentence})
            .center()
            .print()
            .log()      // Make sure to log the participant's progress
            .wait()
            .remove()
        ,
        newImage("img2", row.image)
            .size(888.89, 500)
            .center()
            .print()
            .log()
        ,
        newVar("reactionTime").global().set(v=>Date.now())
        ,
        newKey("key2","AL")
            .log()
            .wait()
        ,
        getVar("reactionTime").set(v=>Date.now()-v )
        ,
        newVar("runningOrder", 0).global().set(v=>v+1)
    )
    .log("id",getVar("ID"))
    .log("group",row.group)
    .log("type",row.type)
    .log("condition",row.condition)
    .log("shape1",row.shape1)
    .log("shape2",row.shape2)
    .log("color",row.color)
    .log("background",row.background)
    .log("sentence",row.sentence)
    .log("truth_value",row.truth_value)
    .log("acc_key",row.acc_key)
    .log("image",row.image)
    .log("cardinality",row.cardinality)
    .log("ratio",row.ratio)
    .log("reactionTime",getVar("reactionTime"))
    .log("runningOrder",getVar("runningOrder")) 
)
// Demographics
newTrial("demographics",
    defaultText.left().print()
    ,
    newText("<p style='font-size: 19px;'>Please fill out below. This will be used for the research purpose only.</p>")
    ,
    newText("When were you born? Please type the year only. (example: 1999)")
    ,
    newTextInput("inputYear", "")
        .left()
        .css("margin","1em")    // Add a 1em margin around this element
        .print()
        .log()
    ,
    newText(" ")
        .print()
    ,
    newText("If you speak other languages in addition to English, please write them and the levels below. (e.g. Spanish:advanced, French:basic...)")
    ,
    newTextInput("language", "")
        .left()
        .css("margin","1em")    // Add a 1em margin around this element
        .print()
        .log()
    ,
    newText(" ")
        .print()
    ,
    newText("Which languages were spoken in your house while growing up? (if multiple, separate them with a comma)")
    ,
    newTextInput("houseLanguage", "")
        .left()
        .css("margin","1em")    // Add a 1em margin around this element
        .print()
        .log()
    ,
    newText(" ")
        .print()
    ,
    newText("Which state are you from? (e.g. Ohio)")
    ,
    newTextInput("region", "")
        .left()
        .css("margin","1em")    // Add a 1em margin around this element
        .print()
        .log()
    ,
    newText(" ")
        .print()
    ,
    newButton("Next")
        .center()
        .print()
        // Only validate a click on Start when inputYear has been filled
        .wait(getTextInput("inputYear").testNot.text(""))
    .log("id",getVar("ID"))
)
// Final screen
newTrial("end",
    defaultText.center().print()
    ,
    newText("<p style='font-size: 19px;'>Thank you very much for your participation!</p>")
    ,
    // Generate Code for Completion
    newText("<p style='font-size: 19px;'>Here is your completion code:</p>")
    ,
    newText("<p style='font-size: 19px;'><b>CKQ38F6E</p></b>")
    ,
    // Trick: stay on this trial forever (until tab is closed)
    newButton().wait()
)
.setOption("countsForProgressBar",false);