int abs(int i) {
  int res;
  select res from details where (i > 2);
  if(i < 0)
    do {return 1;} while (i < 0);
  else 
    res = i;
  return res;
}

int main() {
  return abs(-5);
}
