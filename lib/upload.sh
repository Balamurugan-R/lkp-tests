#!/bin/sh

is_local_server()
{
	[ "$LKP_SERVER" != "${LKP_SERVER#inn}" ] && return
	[ "$LKP_SERVER" != "${LKP_SERVER#192.168.}" ] && return
	return 1
}

upload_files_rsync()
{
	rsync -a --ignore-missing-args --min-size=1 "$@" rsync://$LKP_SERVER$JOB_RESULT_ROOT/
}

upload_files_curl()
{
	local file
	local ret=0

	for file
	do
		curl -T "$file" http://$LKP_SERVER$JOB_RESULT_ROOT/$file || ret=$?
	done

	return $ret
}

upload_files_copy()
{
	chown -R lkp.lkp "$@"
	chmod -R ug+w "$@"

	cp -a "$@" $RESULT_ROOT/ && return

	ls -l "$@" $RESULT_ROOT 2>&1
	return 1
}

upload_files()
{
	[ $# -ne 0 ] || return

	if has_cmd rsync && is_local_server; then
		upload_files_rsync "$@"
		return
	fi

	local files=$(find "$@" -type f -size +0 2>/dev/null)
	[ -n "$files" ] || return

	if has_cmd curl; then
		upload_files_curl "$@"
		return
	else
		# NFS is the last resort -- it seems unreliable, either some
		# content has not reached NFS server during post processing, or
		# some files occasionally contain some few '\0' bytes.
		upload_files_copy "$@"
		return
	fi
}
