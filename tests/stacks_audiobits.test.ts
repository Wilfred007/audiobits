
import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

/// <reference path="../types/clarinet.d.ts" />

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const artist1 = accounts.get("wallet_1")!;
const artist2 = accounts.get("wallet_2")!;

describe("Stacks Audiobits Contract Tests", () => {
  it("should register an artist successfully", () => {
    const { result } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-artist",
      [Cl.stringAscii("John Doe")],
      artist1
    );
    
    expect(result).toBeOk(Cl.uint(1));
  });

  it("should fail when registering duplicate artist", () => {
    // First registration should succeed
    const { result: result1 } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-artist",
      [Cl.stringAscii("John Doe")],
      artist1
    );
    expect(result1).toBeOk(Cl.uint(1));

    // Second registration should fail
    const { result: result2 } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-artist",
      [Cl.stringAscii("Jane Doe")],
      artist1
    );
    expect(result2).toBeErr(Cl.uint(101)); // ERR_ALREADY_REGISTERED
  });

  it("should fail when registering with empty name", () => {
    const { result } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-artist",
      [Cl.stringAscii("")],
      artist1
    );
    expect(result).toBeErr(Cl.uint(110)); // ERR_INVALID_NAME
  });

  it("should register a song successfully", () => {
    // First register artist
    const { result: artistResult } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-artist",
      [Cl.stringAscii("John Doe")],
      artist1
    );
    expect(artistResult).toBeOk(Cl.uint(1));

    // Then register song
    const fileHash = new Uint8Array(32).fill(1);
    const { result: songResult } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-song",
      [Cl.stringAscii("My First Song"), Cl.buffer(fileHash)],
      artist1
    );
    expect(songResult).toBeOk(Cl.uint(1));

    // Verify song was registered correctly
    const getSong = simnet.callReadOnlyFn(
      "stacks_audiobits",
      "get-song",
      [Cl.uint(1)],
      deployer
    );
    
    expect(getSong.result).toBeOk(
      Cl.tuple({
        title: Cl.stringAscii("My First Song"),
        "artist-id": Cl.uint(1),
        "file-hash": Cl.buffer(fileHash)
      })
    );
  });

  it("should fail when non-artist tries to register song", () => {
    const fileHash = new Uint8Array(32).fill(1);
    const { result } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-song",
      [Cl.stringAscii("My First Song"), Cl.buffer(fileHash)],
      artist2 // Not registered as artist
    );
    expect(result).toBeErr(Cl.uint(104)); // ERR_NOT_ARTIST
  });

  it("should fail when registering song with empty title", () => {
    // Register artist first
    const { result: artistResult } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-artist",
      [Cl.stringAscii("John Doe")],
      artist1
    );
    expect(artistResult).toBeOk(Cl.uint(1));

    // Try to register song with empty title
    const fileHash = new Uint8Array(32).fill(1);
    const { result } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-song",
      [Cl.stringAscii(""), Cl.buffer(fileHash)],
      artist1
    );
    expect(result).toBeErr(Cl.uint(110)); // ERR_INVALID_NAME
  });

  it("should fail when registering duplicate file hash", () => {
    // Register artist first
    const { result: artistResult } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-artist",
      [Cl.stringAscii("John Doe")],
      artist1
    );
    expect(artistResult).toBeOk(Cl.uint(1));

    const fileHash = new Uint8Array(32).fill(1);
    
    // Register first song
    const { result: song1Result } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-song",
      [Cl.stringAscii("Song One"), Cl.buffer(fileHash)],
      artist1
    );
    expect(song1Result).toBeOk(Cl.uint(1));

    // Try to register second song with same hash
    const { result: song2Result } = simnet.callPublicFn(
      "stacks_audiobits",
      "register-song",
      [Cl.stringAscii("Song Two"), Cl.buffer(fileHash)],
      artist1
    );
    expect(song2Result).toBeErr(Cl.uint(111)); // ERR_DUPLICATE_FILE_HASH
  });

});
