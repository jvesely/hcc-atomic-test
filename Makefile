PROJECT1=atomic-swap
PROJECT2=atomic-cmp-swap
SRCS1= \
	swap.cpp
SRCS2= \
	cmp-swap.cpp

OBJS1=$(SRCS1:.cpp=.o)
OBJS2=$(SRCS2:.cpp=.o)
DEPS1=$(SRCS1:.cpp=.d)
DEPS2=$(SRCS2:.cpp=.d)

KMT_CPPFLAGS=-I /opt/hsakmt/include
KMT_LDFLAGS=-L/opt/hsakmt/lib/ -lhsakmt

HCC_CONFIG=/opt/hcc-amdgpu/bin/hcc-config
CXX=/opt/hcc-amdgpu/bin/clang++

#hcc-config mixes compiler and preprocessor flags
HCC_CPPFLAGS=$(shell $(HCC_CONFIG) --cxxflags --install)
HCC_CXXFLAGS=$(shell $(HCC_CONFIG) --cxxflags --install)
HCC_LDFLAGS=$(shell $(HCC_CONFIG) --ldflags --install)

CPP_FLAGS=$(KMT_CPPFLAGS) $(HCC_CPPFLAGS)
CXX_FLAGS=$(HCC_CXXFLAGS)
LD_FLAGS=$(KMT_LDFLAGS) $(HCC_LDFLAGS)

all: $(PROJECT1) $(PROJECT2)

$(PROJECT1): $(OBJS1)
	$(CXX) $^ -o $@ $(LD_FLAGS)

$(PROJECT2): $(OBJS2)
	$(CXX) $^ -o $@ $(LD_FLAGS)

%.o: %.cpp
	$(CXX) -c $< $(CPP_FLAGS) $(CXX_FLAGS) -o $@

%.d: %.cpp
	$(CXX) -MMD -MF $@ $(CPP_FLAGS) $< -E > /dev/null

-include $(DEPS1)

clean:
	rm -vf $(OBJS1) $(PROJECT1) $(DEPS1)
