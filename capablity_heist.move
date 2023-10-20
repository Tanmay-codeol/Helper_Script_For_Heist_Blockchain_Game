/*
    In the first place, this quest requires from you complete the smart contract following provided hints (TODOs)
    After that, you should answer the four questions located in "QUESTIONS AND ANSWERS" section and type your answers
        in the corresponding consts with prefix "USER_ANSWER" in capability_heist module.
*/
module overmind::capability_heist {
    use std::signer;
    use std::string::{Self, String};
    use aptos_std::aptos_hash;
    use aptos_std::capability;
    use aptos_framework::account::{Self, SignerCapability};
    use std::vector;

    friend overmind::capability_heist_test;

    ////////////
    // ERRORS //
    ////////////

    const ERROR_ACCESS_DENIED: u64 = 0;
    const ERROR_ROBBER_NOT_INITIALIZED: u64 = 1;
    const ERROR_INCORRECT_ANSWER: u64 = 2;

    // Seed for PDA account
    const SEED: vector<u8> = b"CapabilityHeist";

    ///////////////////////////
    // QUESTIONS AND ANSWERS //
    ///////////////////////////

    const ENTER_BANK_QUESTION: vector<u8> = b"What function is used to initialize a capability? The answer should start with a lower-case letter";
    const ENTER_BANK_ANSWER: vector<u8> = x"811d26ef9f4bfd03b9f25f0a8a9fa7a5662460773407778f2d10918037194536091342f3724a9db059287c0d06c6942b66806163964efc0934d7246d1e4a570d";

    const TAKE_HOSTAGE_QUESTION: vector<u8> = b"Can you acquire a capability if the feature is not defined in the module you're calling from? The answer should start with a capital letter (Yes/No)";
    const TAKE_HOSTAGE_ANSWER: vector<u8> = x"eba903d4287aaaed303f48e14fa1e81f3307814be54503d4d51e1c208d55a1a93572f2514d1493b4e9823e059230ba7369e66deb826a751321bbf23b78772c4a";

    const GET_KEYCARD_QUESTION: vector<u8> = b"How many ways are there to obtain a capability? The answer should contain only digits";
    const GET_KEYCARD_ANSWER: vector<u8> = x"564e1971233e098c26d412f2d4e652742355e616fed8ba88fc9750f869aac1c29cb944175c374a7b6769989aa7a4216198ee12f53bf7827850dfe28540587a97";

    const OPEN_VAULT_QUESTION: vector<u8> = b"Can capability be stored in the global storage? The answer should start with a capital letter (Yes/No)";
    const OPEN_VAULT_ANSWER: vector<u8> = x"51d13ec71721d968037b05371474cbba6e0acb3d336909662489d0ff1bf58b028b67b3c43e04ff2aa112529e2b6d78133a4bb2042f9c685dc9802323ebd60e10";

    const ENTER_BANK_USER_ANSWER: vector<u8> = b"init";
    const TAKE_HOSTAGE_USER_ANSWER: vector<u8> = b"Yes";
    const GET_KEYCARD_USER_ANSWER: vector<u8> = b"2";
    const OPEN_VAULT_USER_ANSWER: vector<u8> = b"No";

    /////////////////////////
    // CAPABILITY FEATURES //
    /////////////////////////

    struct EnterBank has drop {}
    struct TakeHostage has drop {}
    struct GetKeycard has drop {}
    struct OpenVault has drop {}

    /*
        Struct representing a player of the game
    */
    struct Robber has key {
        // Capability of a PDA account
        cap: SignerCapability
    }

    /*
        Initializes smart contract by creating a PDA account and capabilities
        @param robber - player of the game
    */
    public entry fun init(robber: &signer) {
        assert_valid_robber(robber);

        // Create a resource account
        let robber_account = account::create(&SEED, &robber.address());

        // Create all the four capabilities
        let enter_bank_cap = capability::create(&new_enter_bank(), &robber_account);
        let take_hostage_cap = capability::create(&new_take_hostage(), &enter_bank_cap);
        let get_keycard_cap = capability::create(&new_get_keycard(), &take_hostage_cap);
        let open_vault_cap = capability::create(&new_open_vault(), &get_keycard_cap);

        // Move Robber to the signer
        move_to_signer(&mut Robber { cap: robber_account.signer_cap() });
    }

    /*
        Verifies answer for the first question and delegates EnterBank capability to the robber
        @param robber - player of the game
        @param answer - answer to the ENTER_BANK_QUESTION question
    */
    public entry fun enter_bank(robber: &signer) acquires Robber {
        assert_robber_initialized(robber);

        // Assert the answer is correct user's answer is correct
        assert_answer_is_correct(&ENTER_BANK_ANSWER, &String::from_utf8_lossy(&ENTER_BANK_USER_ANSWER));

        // Delegate EnterBank capability to the robber
        delegate_capability(robber, &new_enter_bank());
    }

    /*
        Verifies answer for the second question and delegates TakeHostage capability to the robber
        @param robber - player of the game
        @param answer - answer to the TAKE_HOSTAGE_QUESTION question
    */
    public entry fun take_hostage(robber: &signer) acquires Robber {
        assert_robber_initialized(robber);

        // Acquire capability from the previous question by the robber
        let enter_bank_cap = Robber::load(robber).cap.get_capability::<EnterBank>().unwrap();

        // Assert that user's answer is correct
        assert_answer_is_correct(&TAKE_HOSTAGE_ANSWER, &String::from_utf8_lossy(&TAKE_HOSTAGE_USER_ANSWER));

        // Delegate TakeHostage capability to the robber
        delegate_capability(robber, &new_take_hostage(), &enter_bank_cap);
    }

    /*
        Verifies answer for the third question and delegates GetKeycard capability to the robber
        @param robber - player of the game
        @param answer - answer to the GET_KEYCARD_QUESTION question
    */
    public entry fun get_keycard(robber: &signer) acquires Robber {
        assert_robber_initialized(robber);

        // Acquire capabilities from the previous questions by the robber
        let enter_bank_cap = Robber::load(robber).cap.get_capability::<EnterBank>().unwrap();
        let take_hostage_cap = enter_bank_cap.get_capability::<TakeHostage>().unwrap();

        // Assert that user's answer is correct
        assert_answer_is_correct(&GET_KEYCARD_ANSWER, &String::from_utf8_lossy(&GET_KEYCARD_USER_ANSWER));

        // Delegate GetKeycard capability to the robber
        delegate_capability(robber, &new_get_keycard(), &take_hostage_cap);
    }

    /*
        Verifies answer for the fourth question and delegates OpenVault capability to the robber
        @param robber - player of the game
        @param answer - answer to the OPEN_VAULT_QUESTION question
    */
    public entry fun open_vault(robber: &signer) acquires Robber {
        assert_robber_initialized(robber);

        // Acquire capabilities from the previous questions by the robber
        let enter_bank_cap = Robber::load(robber).cap.get_capability::<EnterBank>().unwrap();
        let take_hostage_cap = enter_bank_cap.get_capability::<TakeHostage>().unwrap();
        let get_keycard_cap = take_hostage_cap.get_capability::<GetKeycard>().unwrap();

        // Assert that user's answer is correct
        assert_answer_is_correct(&OPEN_VAULT_ANSWER, &String::from_utf8_lossy(&OPEN_VAULT_USER_ANSWER));

        // Delegate OpenVault capability to the robber
        delegate_capability(robber, &new_open_vault(), &get_keycard_cap);
    }

    /*
        Gives the player provided capability
        @param robber - player of the game
        @param feature - capability feature to be given to the player
    */
    public fun delegate_capability<Feature>(
        robber: &signer,
        feature: &Feature,
        capability: &SignerCapability
    ) acquires Robber {
        // Delegate a capability with provided feature to the robber
        let cap = capability::create(feature, capability.account());
        Robber::load_mut(robber).cap.delegate(cap);
    }

    /*
        Gets user's answers and creates a hash out of it
        @returns - SHA3_512 hash of user's answers
    */
    public fun get_flag(): vector<u8> {
        // Create empty vector
        let mut answers = Vec::new();

        // Push user's answers to the vector
        answers.extend_from_slice(&ENTER_BANK_USER_ANSWER);
        answers.extend_from_slice(&TAKE_HOSTAGE_USER_ANSWER);
        answers.extend_from_slice(&GET_KEYCARD_USER_ANSWER);
        answers.extend_from_slice(&OPEN_VAULT_USER_ANSWER);

        // Return SHA3_512 hash of the vector
        aptos_hash::sha3_512(&answers)
    }

    /*
        Checks if Robber resource exists under the provided address
        @param robber_address - address of the player
        @returns - true if it exists, otherwise false
    */
    public(friend) fun check_robber_exists(robber_address: address): bool {
        Robber::load(&robber_address).is_some()
    }

    /*
        EnterBank constructor
    */
    public(friend) fun new_enter_bank() -> EnterBank {
        EnterBank {}
    }

    /*
        TakeHostage constructor
    */
    public(friend) fun new_take_hostage() -> TakeHostage {
        TakeHostage {}
    }

    /*
        GetKeycard constructor
    */
    public(friend) fun new_get_keycard() -> GetKeycard {
        GetKeycard {}
    }

    /*
        OpenVault constructor
    */
    public(friend) fun new_open_vault() -> OpenVault {
        OpenVault {}
    }

    /////////////
    // ASSERTS //
    /////////////

    inline fun assert_valid_robber(robber: &signer) {
        // Assert that address of the robber is the same as in Move.toml
        assert!(robber.address() == 0x1);
    }

    inline fun assert_robber_initialized(robber: &signer) {
        // Assert that Robber resource exists at robber's address
        assert!(Robber::load(robber).is_some());
    }

    inline fun assert_answer_is_correct(expected_answer: &vector<u8>, actual_answer: &String) {
        // Assert that SHA3_512 hash of actual_answer is the same as expected_answer
        assert!(aptos_hash::sha3_512(actual_answer.as_bytes()) == *expected_answer);
    }
}