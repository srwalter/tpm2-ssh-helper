tpm2-ssh-helper
===============
This package aims to simplify using a TPM-based security architecture,
specifically for SSH keys.  The idea is that one system acts as an issuing
authority, and created keys can be duplicated to other systems.

Advantages:
 * Similar to a smart card or hardware key, this ensures that duplication of
   the keys is controlled, and only systems that are approved by the issuing
   authority may receive the keys.
 * Allows for the same key to be installed on multiple systems, which would
   otherwise require issuing multiple hardware keys.
 * The issuing authority can ensure that keys are protected by a password,
   unlike e.g. normal SSH key files which can be created unprotected.
 * The key passwords are protected from brute force attack by the TPM.

Disadvantages:
 * Unlike a smart card or hardware key, the key is tied to a particular system,
   rather than being portable.  This is mitigated somewhat by duplicating the
   key to multiple machines.
 * Requires every system to have TPM 2.0 capability
 * General complexity

Given the above, this system is well-suited for situations where managing
multiple keys per user is more difficult than managing this issuing authority.
Further, it is best in cases where users generally use a small number of
machines as their physical terminal.  For remote access an SSH agent can be
forwarded as with any other key solution.

Usage
=====
First, the system that will be used as the issuing authority needs to be initialized:

    [issuer]$ ./tpm-ssh-helper create-issuer

This will create a storage directory at $HOME/.tpm-helper and populate it.  At
this point keys can now be generated:

    [issuer]$ ./tpm-ssh-helper new-key <keyname>

At this point the key can only be used on the issuing system, which is not
particularly useful.  We want to duplicate the key to the user's system, but
first we need to prepare that system:

    [user]$ ./tpm-ssh-helper setup-ssh

This will initialize tpm2-pkcs11, so that we can add our key to it later.  We
also need to do some initialization of the user's TPM:

    [user]$ ./tpm-ssh-helper create-user-srk

This creates a Storage Root Key on the users system which will hold their copy
of the key.  Note that if you're particularly paranoid, then an administrator
should run this command themselves.  Otherwise a user intending to circumvent
the system could create an SRK on a software TPM, and then trivially extract
the private key from there.  If additional arguments to tpm2\_createprimary are
needed (such as if an owner authorization is set) then those parameters can be
passed as extra parameters to create-user-srk.

The generated .pub file should be transmitted to the issuing system, and then
the user key can be duplicated:

    [issuer]$ ./tpm-ssh-helper duplicate-key user.pub <keyname>

This creates two more files, a .priv and a .seed, that need to be transmitted
back to the user's system, along with the .pub for the key and the policy found
at ~/.tpm-helper/duplicate\_policy.dat

Back on the user system, the new key can be imported into the TPM:

    [user]$ ./tpm-ssh-helper import-key key.pub key.priv key.seed duplicate_policy.dat

At long last, the key can be used with SSH (or really, for any desired
purpose).

The user can now use ssh-keygen to get the public ID of the key, and use
ssh-add to add the key to his SSH agent:

    [user]$ ssh-keygen -D /usr/lib/x86_64-linux-gnu/pkcs11/libtpm2_pkcs11.so
    [user]$ ssh-add -s /usr/lib/x86_64-linux-gnu/pkcs11/libtpm2_pkcs11.so
