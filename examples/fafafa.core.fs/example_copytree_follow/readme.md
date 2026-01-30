# Example: FsCopyTreeEx with FollowSymlinks (True vs False)

This example builds and runs a tiny program that creates a small directory tree with a symlink,
then runs FsCopyTreeEx twice to demonstrate behavioral difference:
- FollowSymlinks=False: the symlink is skipped (neither link nor target content is copied)
- FollowSymlinks=True: the target content is copied into the destination

Windows symlink creation typically requires Administrator or Developer Mode; the program tolerates failure and exits gracefully.

