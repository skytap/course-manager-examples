export function raise_error(msg) {
  console.log(msg);
  process.exit(1);
}

export function log(msg) {
  console.log(msg);
}

export function deep_log(obj) {
  console.dir(obj, { depth: null });
}

export function compare(str1, str2) {
  return str1.trim().toLowerCase() === str2.trim().toLowerCase();
}

export function any(val) {
  return !none(val);
}

export function none(val) {
  if (!val) {
    return true;
  } 
  switch (typeof val) {
  case 'array':
    return val.length === 0;

  case 'object':
    return Object.keys(val).length === 0;

  default:
    return false;
  } 
}
