
MAIN_SRCS= \
	cmp-swap.cpp \
	load.cpp \
	swap.cpp \

AUX_SRCS= \

BINS=$(addprefix atomic-, $(subst .cpp,,$(MAIN_SRCS)))

SRCS=$(MAIN_SRCS) $(AUX_SRCS)
OBJS=$(SRCS:.cpp=.o)
DEPS=$(SRCS:.cpp=.d)

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

all: $(BINS)

atomic-% : %.o
	$(CXX) $^ -o $@ $(LD_FLAGS)

%.o: %.cpp
	$(CXX) -c $< $(CPP_FLAGS) $(CXX_FLAGS) -o $@

%.d: %.cpp
	$(CXX) -MMD -MF $@ $(CPP_FLAGS) $< -E > /dev/null

-include $(DEPS)

clean:
	rm -vf $(OBJS) $(BINS) $(DEPS)
